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
  getExerciseVideoInfo,
  getWorkoutWarmup,
  getWorkoutStretches,
  createWorkoutWarmupAndStretches,
  updateWorkoutExercises,
  logWorkoutExit,
  type VideoResponse,
  type WarmupResponse,
  type StretchResponse,
  type LibraryExercise,
  type WorkoutExerciseItem,
  type WorkoutExitReason,
} from '../api/client';
import { useAppStore } from '../store';
import SetRow from '../components/workout/SetRow';
import BottomSheet from '../components/workout/BottomSheet';
import ExerciseListModal from '../components/workout/ExerciseListModal';
import VideoPlayer from '../components/workout/VideoPlayer';
import ExerciseSwapModal from '../components/ExerciseSwapModal';
import HydrationTracker from '../components/workout/HydrationTracker';
import WorkoutFeedbackModal from '../components/workout/WorkoutFeedbackModal';
import type { Workout, ActiveSet, PerformanceLogDetailed, StrengthRecord, WorkoutExercise } from '../types';

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

export default function ActiveWorkout() {
  const { id } = useParams<{ id: string }>();
  const navigate = useNavigate();
  const queryClient = useQueryClient();
  const { user, setCurrentWorkout } = useAppStore();

  const [currentExerciseIndex, setCurrentExerciseIndex] = useState(0);
  // Separate state for accordion expansion - null means none expanded
  const [expandedExerciseIndex, setExpandedExerciseIndex] = useState<number | null>(0);
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
  const [videoInfo, setVideoInfo] = useState<VideoResponse | null>(null);
  const [videoLoading, setVideoLoading] = useState(false);
  // Default to 'male' - gender preference can be updated via the toggle
  const [selectedGender, setSelectedGender] = useState<'male' | 'female'>('male');
  // Warmup and stretches state
  const [warmup, setWarmup] = useState<WarmupResponse | null>(null);
  const [stretches, setStretches] = useState<StretchResponse | null>(null);
  const [warmupStretchLoading, setWarmupStretchLoading] = useState(false);
  const [warmupExpanded, setWarmupExpanded] = useState(false);
  const [stretchesExpanded, setStretchesExpanded] = useState(false);
  // Layout preference: video on left (true) or right (false) - persists to localStorage
  const [videoOnLeft, setVideoOnLeft] = useState<boolean>(() => {
    const saved = localStorage.getItem('workout-video-position');
    return saved !== 'right'; // Default to left if not set
  });
  // Exercise swap modal state
  const [showSwapModal, setShowSwapModal] = useState(false);
  const [swapExerciseIndex, setSwapExerciseIndex] = useState<number | null>(null);

  // Exit confirmation modal state
  const [showExitModal, setShowExitModal] = useState(false);
  const [selectedExitReason, setSelectedExitReason] = useState<WorkoutExitReason | null>(null);
  const [exitNotes, setExitNotes] = useState('');
  const [isExiting, setIsExiting] = useState(false);

  // Feedback modal state
  const [showFeedbackModal, setShowFeedbackModal] = useState(false);

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

  // Fetch video URL when exercise or gender changes
  useEffect(() => {
    const currentExercise = workout?.exercises[currentExerciseIndex];
    if (!currentExercise?.name) return;

    setVideoLoading(true);
    setVideoInfo(null);

    getExerciseVideoInfo(currentExercise.name, selectedGender)
      .then((info) => setVideoInfo(info))
      .finally(() => setVideoLoading(false));
  }, [workout?.exercises, currentExerciseIndex, selectedGender]);

  // Fetch warmup and stretches when workout loads
  useEffect(() => {
    if (!workout?.id) return;

    const fetchWarmupAndStretches = async () => {
      setWarmupStretchLoading(true);
      try {
        // Try to get existing warmup and stretches
        const [warmupData, stretchData] = await Promise.all([
          getWorkoutWarmup(workout.id),
          getWorkoutStretches(workout.id),
        ]);

        if (warmupData) {
          setWarmup(warmupData);
        }
        if (stretchData) {
          setStretches(stretchData);
        }

        // If neither exist, generate them
        if (!warmupData && !stretchData) {
          const result = await createWorkoutWarmupAndStretches(workout.id);
          setWarmup(result.warmup);
          setStretches(result.stretches);
        } else if (!warmupData) {
          // Only warmup missing - this shouldn't happen normally
          console.log('Warmup not found, stretches exist');
        } else if (!stretchData) {
          // Only stretches missing - this shouldn't happen normally
          console.log('Stretches not found, warmup exists');
        }
      } catch (error) {
        console.error('Failed to fetch warmup/stretches:', error);
      } finally {
        setWarmupStretchLoading(false);
      }
    };

    fetchWarmupAndStretches();
  }, [workout?.id]);

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
      // Show feedback modal instead of navigating immediately
      setShowFeedbackModal(true);
    },
  });

  // Handle feedback modal close - navigate home
  const handleFeedbackClose = () => {
    setShowFeedbackModal(false);
    navigate('/home');
  };

  // Exit workout mutation (for tracking quit reasons)
  const exitMutation = useMutation({
    mutationFn: (reason: WorkoutExitReason) => {
      const exercises = workout?.exercises || [];
      const completedSetsCount = Array.from(exerciseSets.values()).flat().filter(s => s.isCompleted).length;
      const completedExercisesCount = Array.from(exerciseSets.entries()).filter(
        ([, sets]) => sets.length > 0 && sets.every(s => s.isCompleted)
      ).length;
      const totalExercises = exercises.length;
      const progressPercentage = totalExercises > 0
        ? Math.round((completedExercisesCount / totalExercises) * 100)
        : 0;

      return logWorkoutExit(id!, {
        user_id: String(user?.id || ''),
        workout_id: id!,
        exit_reason: reason,
        exit_notes: exitNotes || undefined,
        exercises_completed: completedExercisesCount,
        total_exercises: totalExercises,
        sets_completed: completedSetsCount,
        time_spent_seconds: totalElapsedTime,
        progress_percentage: progressPercentage,
      });
    },
    onSuccess: () => {
      setShowExitModal(false);
      // Don't navigate here - handleConfirmExit will handle it
      // If completed, it will call completeMutation which shows feedback
      // If not completed, we navigate home below
    },
    onError: (error) => {
      console.error('Failed to log workout exit:', error);
      setShowExitModal(false);
    },
  });

  // Handle exit button click - show modal
  const handleExitClick = () => {
    setShowExitModal(true);
    setSelectedExitReason(null);
    setExitNotes('');
  };

  // Handle confirming exit with reason
  const handleConfirmExit = async () => {
    if (!selectedExitReason) return;
    setIsExiting(true);
    try {
      // Log the exit reason
      await exitMutation.mutateAsync(selectedExitReason);

      // If user selected "completed", mark the workout as done and show feedback modal
      if (selectedExitReason === 'completed') {
        await completeMutation.mutateAsync();
        // completeMutation.onSuccess will show the feedback modal
      } else {
        // For non-completed exits, navigate home directly
        navigate('/home');
      }
    } catch (error) {
      console.error('Failed to exit workout:', error);
      // Even on error, navigate home so user isn't stuck
      navigate('/home');
    } finally {
      setIsExiting(false);
    }
  };

  // Update exercises mutation (for swapping)
  const updateExercisesMutation = useMutation({
    mutationFn: (exercises: WorkoutExerciseItem[]) =>
      updateWorkoutExercises(id!, exercises),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['workout', id] });
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

    // Calculate set duration
    const endTime = Date.now();
    const durationSeconds = set.startTime
      ? Math.round((endTime - set.startTime) / 1000)
      : undefined;

    // Mark set as completed with timing data
    const updatedSets = [...currentSets];
    updatedSets[setIndex] = {
      ...set,
      isCompleted: true,
      endTime,
      durationSeconds,
    };
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
          set_type: set.setType,
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

  const handleSetFocus = (exerciseIndex: number, setIndex: number) => {
    const currentSets = exerciseSets.get(exerciseIndex);
    if (!currentSets) return;

    const set = currentSets[setIndex];
    // Only start timing if not already started and not completed
    if (!set.startTime && !set.isCompleted) {
      const updatedSets = [...currentSets];
      updatedSets[setIndex] = { ...set, startTime: Date.now() };
      setExerciseSets(new Map(exerciseSets.set(exerciseIndex, updatedSets)));
    }
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

  const handleDeleteSet = (exerciseIndex: number, setIndex: number) => {
    const currentSets = exerciseSets.get(exerciseIndex);
    if (!currentSets || currentSets.length <= 1) return; // Don't delete the last set

    const updatedSets = currentSets.filter((_, index) => index !== setIndex);
    // Renumber working sets
    let workingSetNumber = 1;
    const renumberedSets = updatedSets.map((set) => {
      if (set.setType === 'working') {
        return { ...set, setNumber: workingSetNumber++ };
      }
      return set;
    });

    setExerciseSets(new Map(exerciseSets.set(exerciseIndex, renumberedSets)));
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

  const handleSkipRest = useCallback(() => {
    setIsResting(false);
    setRestTimer(null);
  }, []);

  const toggleVideoPosition = useCallback(() => {
    setVideoOnLeft((prev) => {
      const newValue = !prev;
      localStorage.setItem('workout-video-position', newValue ? 'left' : 'right');
      return newValue;
    });
  }, []);

  const goToNextExercise = () => {
    if (workout && currentExerciseIndex < workout.exercises.length - 1) {
      const nextIndex = currentExerciseIndex + 1;
      setCurrentExerciseIndex(nextIndex);
      setExpandedExerciseIndex(nextIndex);
      setSheetExpanded(false);
    }
  };

  // Handle exercise swap
  const handleSwapExercise = async (newExercise: LibraryExercise, sets: number, reps: number) => {
    if (swapExerciseIndex === null || !workout) return;

    const currentExerciseData = workout.exercises[swapExerciseIndex];

    try {
      // Create updated exercises array with the swapped exercise
      const updatedExercises: WorkoutExerciseItem[] = workout.exercises.map((ex, idx) => {
        if (idx === swapExerciseIndex) {
          return {
            name: newExercise.name,
            sets,
            reps,
            weight: currentExerciseData.weight,
            rest_seconds: currentExerciseData.rest_seconds || 90,
            notes: currentExerciseData.notes,
            equipment: newExercise.equipment || 'bodyweight',
            target_muscles: newExercise.target_muscle ? [newExercise.target_muscle] : undefined,
          };
        }
        return {
          name: ex.name,
          sets: ex.sets,
          reps: ex.reps,
          weight: ex.weight,
          rest_seconds: ex.rest_seconds || 90,
          notes: ex.notes,
          equipment: ex.equipment,
          target_muscles: ex.muscle_group ? [ex.muscle_group] : undefined,
        };
      });

      await updateExercisesMutation.mutateAsync(updatedExercises);

      // Reset the sets for the swapped exercise
      const newSets: ActiveSet[] = [];
      for (let i = 1; i <= sets; i++) {
        newSets.push({
          setNumber: i,
          setType: 'working',
          targetWeight: 0,
          targetReps: reps,
          actualWeight: 0,
          actualReps: reps,
          isCompleted: false,
        });
      }
      setExerciseSets(new Map(exerciseSets.set(swapExerciseIndex, newSets)));

      setShowSwapModal(false);
      setSwapExerciseIndex(null);
    } catch (error) {
      console.error('Failed to swap exercise:', error);
    }
  };

  const openSwapModal = (exerciseIndex: number) => {
    setSwapExerciseIndex(exerciseIndex);
    setShowSwapModal(true);
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
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-2 flex-wrap">
            <span className="text-xs px-2 py-0.5 bg-white/10 rounded-full text-text-secondary uppercase tracking-wider">
              {currentExercise.equipment || 'Bodyweight'}
            </span>
            {currentExercise.muscle_group && (
              <span className="text-xs px-2 py-0.5 bg-primary/20 rounded-full text-primary uppercase tracking-wider">
                {currentExercise.muscle_group}
              </span>
            )}
          </div>
          {/* Swap button */}
          <button
            onClick={() => openSwapModal(currentExerciseIndex)}
            className="flex items-center gap-1 px-2.5 py-1 text-xs bg-white/10 hover:bg-white/20 rounded-lg text-text-secondary hover:text-text transition-colors"
          >
            <svg className="w-3.5 h-3.5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M8 7h12m0 0l-4-4m4 4l-4 4m0 6H4m0 0l4 4m-4-4l4-4" />
            </svg>
            Swap
          </button>
        </div>
        <h2 className="text-xl font-bold text-text">{currentExercise.name}</h2>
        <p className="text-text-secondary">{currentExercise.sets} sets × {currentExercise.reps} reps</p>
      </div>

      {/* Current set-by-set table */}
      <div className="rounded-xl overflow-hidden">
        <div className="flex items-center gap-2 px-3 py-2 text-text-muted text-xs font-medium uppercase tracking-wider">
          <div className="w-8 text-center">Set</div>
          <div className="w-16 text-center">Prev</div>
          <div className="flex-1 max-w-16 text-center">Wt</div>
          <div className="flex-1 max-w-16 text-center">Reps</div>
          <div className="w-14 text-center">Time</div>
          <div className="w-8 text-center"></div>
        </div>
        <div className="space-y-1.5">
          {currentSets.map((set, index) => (
            <SetRow
              key={index}
              set={set}
              isActive={index === currentSetIndex}
              onWeightChange={(weight) => handleWeightChange(currentExerciseIndex, index, weight)}
              onRepsChange={(reps) => handleRepsChange(currentExerciseIndex, index, reps)}
              onComplete={() => handleSetComplete(currentExerciseIndex, index)}
              onSetTypeChange={(type) => handleSetTypeChange(currentExerciseIndex, index, type)}
              onSetFocus={() => handleSetFocus(currentExerciseIndex, index)}
              onDelete={currentSets.length > 1 ? () => handleDeleteSet(currentExerciseIndex, index) : undefined}
            />
          ))}
        </div>
        <div className="pt-2">
          <button
            onClick={() => handleAddSet(currentExerciseIndex)}
            className="w-full py-2 border-2 border-dashed border-white/15 rounded-xl text-text-secondary hover:border-primary hover:text-primary transition-colors flex items-center justify-center gap-2 text-sm"
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
          className="flex-shrink-0 w-12 h-12 rounded-xl bg-white/10 flex items-center justify-center text-text-secondary hover:bg-white/20 transition-colors"
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

  // Handle accordion toggle
  const handleAccordionClick = (index: number) => {
    if (expandedExerciseIndex === index) {
      // Clicking the same exercise - toggle closed
      setExpandedExerciseIndex(null);
    } else {
      // Clicking a different exercise - expand it and make it current
      setExpandedExerciseIndex(index);
      setCurrentExerciseIndex(index);
    }
  };

  // Expanded content - accordion style with inline set details
  const expandedContent = (
    <div className="space-y-2">
      {/* Warmup Section */}
      {warmup && warmup.exercises_json && warmup.exercises_json.length > 0 && (
        <div className="space-y-0">
          <button
            onClick={() => setWarmupExpanded(!warmupExpanded)}
            className={`
              w-full flex items-center gap-3 p-3 rounded-xl
              transition-all duration-200
              ${warmupExpanded ? 'bg-orange-500/20' : 'bg-orange-500/10'}
            `}
          >
            <div className="w-8 h-8 rounded-lg flex items-center justify-center bg-orange-500/20 text-orange-400 flex-shrink-0">
              <span className="text-lg">🔥</span>
            </div>
            <div className="flex-1 text-left min-w-0">
              <p className={`font-medium text-sm ${warmupExpanded ? 'text-orange-400' : 'text-text'}`}>
                Warm-Up
              </p>
              <p className="text-xs text-text-muted">
                {warmup.exercises_json.length} exercises • {warmup.duration_minutes} min
              </p>
            </div>
            <svg
              className={`w-4 h-4 text-text-muted transition-transform duration-200 ${warmupExpanded ? 'rotate-180' : ''}`}
              fill="none"
              stroke="currentColor"
              viewBox="0 0 24 24"
            >
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 9l-7 7-7-7" />
            </svg>
          </button>
          {warmupExpanded && (
            <div className="mt-2 ml-4 pl-4 border-l-2 border-orange-500/30 space-y-2 pb-2">
              {warmup.exercises_json.map((ex, idx) => (
                <div key={idx} className="bg-white/5 rounded-lg p-3">
                  <div className="flex items-center justify-between">
                    <span className="font-medium text-sm text-text">{ex.name}</span>
                    <span className="text-xs text-orange-400 bg-orange-500/20 px-2 py-0.5 rounded-full">
                      {ex.duration_seconds}s
                    </span>
                  </div>
                  <p className="text-xs text-text-muted mt-1">
                    {ex.reps > 1 ? `${ex.reps} reps` : ''} {ex.muscle_group && `• ${ex.muscle_group}`}
                  </p>
                  {ex.notes && (
                    <p className="text-xs text-text-secondary mt-1 italic">{ex.notes}</p>
                  )}
                </div>
              ))}
            </div>
          )}
        </div>
      )}

      {/* Loading state for warmup/stretches */}
      {warmupStretchLoading && (
        <div className="flex items-center gap-2 p-3 bg-white/5 rounded-xl">
          <div className="w-5 h-5 border-2 border-primary border-t-transparent rounded-full animate-spin" />
          <span className="text-sm text-text-secondary">Loading warmup & stretches...</span>
        </div>
      )}

      {/* Hydration Tracker */}
      {user && (
        <HydrationTracker
          userId={String(user.id)}
          workoutId={workout.id}
        />
      )}

      {/* Accordion Exercise List */}
      {workout.exercises.map((exercise, index) => {
        const sets = exerciseSets.get(index) || [];
        const isComplete = sets.length > 0 && sets.every((s) => s.isCompleted);
        const isExpanded = index === expandedExerciseIndex;
        const isCurrent = index === currentExerciseIndex;
        const completedSetsCount = sets.filter(s => s.isCompleted).length;
        const activeSetIndex = sets.findIndex((s) => !s.isCompleted);

        return (
          <div key={index} className="space-y-0">
            {/* Exercise Header Row */}
            <button
              onClick={() => handleAccordionClick(index)}
              className={`
                w-full flex items-center gap-3 p-3 rounded-xl
                transition-all duration-200
                ${isExpanded
                  ? 'bg-primary/20'
                  : isComplete
                  ? 'bg-emerald-500/10'
                  : isCurrent
                  ? 'bg-white/10'
                  : 'bg-white/5'
                }
              `}
            >
              <div
                className={`
                  w-8 h-8 rounded-lg flex items-center justify-center text-sm font-bold flex-shrink-0
                  ${isComplete
                    ? 'bg-emerald-500 text-white'
                    : isExpanded
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
              <div className="flex-1 text-left min-w-0">
                <p className={`font-medium text-sm truncate ${isExpanded ? 'text-primary' : 'text-text'}`}>
                  {exercise.name}
                </p>
                <p className="text-xs text-text-muted">
                  {exercise.sets}×{exercise.reps} • {exercise.equipment || 'Bodyweight'}
                </p>
              </div>
              <div className="flex items-center gap-2 flex-shrink-0">
                <span className="text-xs text-text-muted">
                  {completedSetsCount}/{sets.length}
                </span>
                <svg
                  className={`w-4 h-4 text-text-muted transition-transform duration-200 ${isExpanded ? 'rotate-180' : ''}`}
                  fill="none"
                  stroke="currentColor"
                  viewBox="0 0 24 24"
                >
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 9l-7 7-7-7" />
                </svg>
              </div>
            </button>

            {/* Expanded Set Details (only for expanded exercise) */}
            {isExpanded && (
              <div className="mt-2 ml-4 pl-4 border-l-2 border-primary/30 space-y-3 pb-2">
                {/* Tags row with swap button */}
                <div className="flex items-center justify-between gap-2">
                  <div className="flex items-center gap-2 flex-wrap">
                    {exercise.muscle_group && (
                      <span className="inline-block text-xs px-2 py-0.5 bg-primary/20 rounded-full text-primary uppercase tracking-wider">
                        {exercise.muscle_group}
                      </span>
                    )}
                  </div>
                  {/* Swap button */}
                  <button
                    onClick={(e) => {
                      e.stopPropagation();
                      openSwapModal(index);
                    }}
                    className="flex items-center gap-1 px-2.5 py-1 text-xs bg-white/10 hover:bg-white/20 rounded-lg text-text-secondary hover:text-text transition-colors"
                  >
                    <svg className="w-3.5 h-3.5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M8 7h12m0 0l-4-4m4 4l-4 4m0 6H4m0 0l4 4m-4-4l4-4" />
                    </svg>
                    Swap
                  </button>
                </div>

                {/* Set-by-set table */}
                <div className="rounded-xl overflow-hidden">
                  <div className="flex items-center gap-2 px-2 py-1.5 text-text-muted text-xs font-medium uppercase tracking-wider">
                    <div className="w-7 text-center">Set</div>
                    <div className="w-16 text-center">Prev</div>
                    <div className="flex-1 max-w-16 text-center">Wt</div>
                    <div className="flex-1 max-w-16 text-center">Reps</div>
                    <div className="w-12 text-center">Time</div>
                    <div className="w-7 text-center"></div>
                  </div>
                  <div className="space-y-1">
                    {sets.map((set, setIndex) => (
                      <SetRow
                        key={setIndex}
                        set={set}
                        isActive={setIndex === activeSetIndex}
                        onWeightChange={(weight) => handleWeightChange(index, setIndex, weight)}
                        onRepsChange={(reps) => handleRepsChange(index, setIndex, reps)}
                        onComplete={() => handleSetComplete(index, setIndex)}
                        onSetTypeChange={(type) => handleSetTypeChange(index, setIndex, type)}
                        onSetFocus={() => handleSetFocus(index, setIndex)}
                        onDelete={sets.length > 1 ? () => handleDeleteSet(index, setIndex) : undefined}
                      />
                    ))}
                  </div>
                  <div className="pt-2">
                    <button
                      onClick={() => handleAddSet(index)}
                      className="w-full py-1.5 border-2 border-dashed border-white/15 rounded-lg text-text-secondary hover:border-primary hover:text-primary transition-colors flex items-center justify-center gap-2 text-sm"
                    >
                      <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 4v16m8-8H4" />
                      </svg>
                      Add Set
                    </button>
                  </div>
                </div>

                {/* AI Coaching Tip */}
                {exercise.notes && (
                  <div className="bg-gradient-to-r from-primary/10 to-cyan-500/10 rounded-lg p-2 border border-primary/20">
                    <div className="flex items-start gap-2">
                      <span className="text-sm">💡</span>
                      <p className="text-xs text-text-secondary">{exercise.notes}</p>
                    </div>
                  </div>
                )}
              </div>
            )}
          </div>
        );
      })}

      {/* Stretches Section */}
      {stretches && stretches.exercises_json && stretches.exercises_json.length > 0 && (
        <div className="space-y-0">
          <button
            onClick={() => setStretchesExpanded(!stretchesExpanded)}
            className={`
              w-full flex items-center gap-3 p-3 rounded-xl
              transition-all duration-200
              ${stretchesExpanded ? 'bg-blue-500/20' : 'bg-blue-500/10'}
            `}
          >
            <div className="w-8 h-8 rounded-lg flex items-center justify-center bg-blue-500/20 text-blue-400 flex-shrink-0">
              <span className="text-lg">🧘</span>
            </div>
            <div className="flex-1 text-left min-w-0">
              <p className={`font-medium text-sm ${stretchesExpanded ? 'text-blue-400' : 'text-text'}`}>
                Cool-Down Stretches
              </p>
              <p className="text-xs text-text-muted">
                {stretches.exercises_json.length} stretches • {stretches.duration_minutes} min
              </p>
            </div>
            <svg
              className={`w-4 h-4 text-text-muted transition-transform duration-200 ${stretchesExpanded ? 'rotate-180' : ''}`}
              fill="none"
              stroke="currentColor"
              viewBox="0 0 24 24"
            >
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 9l-7 7-7-7" />
            </svg>
          </button>
          {stretchesExpanded && (
            <div className="mt-2 ml-4 pl-4 border-l-2 border-blue-500/30 space-y-2 pb-2">
              {stretches.exercises_json.map((ex, idx) => (
                <div key={idx} className="bg-white/5 rounded-lg p-3">
                  <div className="flex items-center justify-between">
                    <span className="font-medium text-sm text-text">{ex.name}</span>
                    <span className="text-xs text-blue-400 bg-blue-500/20 px-2 py-0.5 rounded-full">
                      {ex.duration_seconds}s hold
                    </span>
                  </div>
                  <p className="text-xs text-text-muted mt-1">
                    {ex.muscle_group && `${ex.muscle_group}`}
                  </p>
                  {ex.notes && (
                    <p className="text-xs text-text-secondary mt-1 italic">{ex.notes}</p>
                  )}
                </div>
              ))}
            </div>
          )}
        </div>
      )}

      {/* Finish Button at bottom */}
      <div className="pt-4">
        <button
          onClick={handleFinishWorkout}
          disabled={completeMutation.isPending}
          className="w-full h-12 bg-gradient-to-r from-emerald-500 to-emerald-600 text-white rounded-xl font-semibold flex items-center justify-center gap-2 hover:shadow-lg hover:shadow-emerald-500/30 disabled:opacity-50 transition-all"
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
      </div>
    </div>
  );

  // Video player props for reuse
  const videoPlayerProps = {
    videoInfo,
    videoLoading,
    selectedGender,
    onGenderChange: setSelectedGender,
    exerciseName: currentExercise.name,
    exerciseIndex: currentExerciseIndex,
    totalExercises: workout.exercises.length,
    muscleGroup: currentExercise.muscle_group,
    isResting,
    restTimer,
    onSkipRest: handleSkipRest,
    exerciseCompleted,
  };

  // Desktop workout panel content
  const desktopWorkoutPanel = (
    <div className="h-full flex flex-col bg-surface overflow-hidden">
      {/* Header */}
      <div className="p-4 border-b border-white/10">
        <div className="flex items-center justify-between mb-3">
          <button
            onClick={handleExitClick}
            className="w-10 h-10 bg-white/10 rounded-full flex items-center justify-center text-text-secondary hover:bg-white/20 transition-colors"
          >
            <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 19l-7-7 7-7" />
            </svg>
          </button>
          <div className="bg-white/10 rounded-full px-4 py-2 flex items-center gap-2">
            <svg className="w-4 h-4 text-text-secondary" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z" />
            </svg>
            <span className="text-text font-mono font-semibold">{formatTime(totalElapsedTime)}</span>
          </div>
          <button
            onClick={() => setIsPaused(!isPaused)}
            className={`w-10 h-10 rounded-full flex items-center justify-center transition-colors ${
              isPaused ? 'bg-primary text-white' : 'bg-white/10 text-text-secondary hover:bg-white/20'
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
        <div className="h-1 bg-white/10 rounded-full overflow-hidden">
          <div
            className="h-full bg-gradient-to-r from-primary to-emerald-400 transition-all duration-500"
            style={{ width: `${progress}%` }}
          />
        </div>
      </div>

      {/* Scrollable content */}
      <div className="flex-1 overflow-y-auto p-4">
        {expandedContent}
      </div>
    </div>
  );

  return (
    <div className="min-h-screen bg-background">
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
            setExpandedExerciseIndex(index);
            setSheetExpanded(false);
          }}
          onClose={() => setShowExerciseList(false)}
        />
      )}

      {/* Exercise Swap Modal */}
      <ExerciseSwapModal
        isOpen={showSwapModal}
        onClose={() => {
          setShowSwapModal(false);
          setSwapExerciseIndex(null);
        }}
        currentExercise={swapExerciseIndex !== null ? (workout.exercises[swapExerciseIndex] as WorkoutExercise) : null}
        onSwap={handleSwapExercise}
      />

      {/* DESKTOP LAYOUT (lg and up) - Side by side with toggle */}
      <div className="hidden lg:flex h-screen relative">
        {/* Layout Toggle Button - centered between panels */}
        <button
          onClick={toggleVideoPosition}
          className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 z-30 w-10 h-10 bg-white/10 hover:bg-white/20 backdrop-blur-lg rounded-full flex items-center justify-center text-white transition-all duration-300 shadow-lg hover:scale-110 border border-white/20"
          title={videoOnLeft ? 'Move video to right' : 'Move video to left'}
        >
          <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M8 7h12m0 0l-4-4m4 4l-4 4m0 6H4m0 0l4 4m-4-4l4-4" />
          </svg>
        </button>

        {videoOnLeft ? (
          <>
            {/* Video on Left */}
            <div className="w-1/2 xl:w-3/5 h-full">
              <VideoPlayer {...videoPlayerProps} />
            </div>
            {/* Workout Panel on Right */}
            <div className="w-1/2 xl:w-2/5 h-full border-l border-white/10">
              {desktopWorkoutPanel}
            </div>
          </>
        ) : (
          <>
            {/* Workout Panel on Left */}
            <div className="w-1/2 xl:w-2/5 h-full border-r border-white/10">
              {desktopWorkoutPanel}
            </div>
            {/* Video on Right */}
            <div className="w-1/2 xl:w-3/5 h-full">
              <VideoPlayer {...videoPlayerProps} />
            </div>
          </>
        )}
      </div>

      {/* MOBILE LAYOUT (below lg) - Stacked with bottom sheet */}
      <div className="lg:hidden flex flex-col min-h-screen">
        {/* Floating Header with Timer */}
        <header className="fixed top-0 left-0 right-0 z-30 px-4 py-3 safe-area-top">
          <div className="flex items-center justify-between">
            <button
              onClick={handleExitClick}
              className="w-10 h-10 bg-black/40 backdrop-blur-lg rounded-full flex items-center justify-center text-white hover:bg-black/60 transition-colors"
            >
              <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 19l-7-7 7-7" />
              </svg>
            </button>
            <div className="bg-black/40 backdrop-blur-lg rounded-full px-4 py-2 flex items-center gap-2">
              <svg className="w-4 h-4 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z" />
              </svg>
              <span className="text-white font-mono font-semibold">{formatTime(totalElapsedTime)}</span>
            </div>
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
          <div className="absolute inset-0 pt-20">
            <VideoPlayer {...videoPlayerProps} />
          </div>
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
        .safe-area-top {
          padding-top: max(12px, env(safe-area-inset-top));
        }
      `}</style>

      {/* Exit Confirmation Modal */}
      {showExitModal && (
        <div className="fixed inset-0 z-[60] flex items-center justify-center p-4 bg-black/60 backdrop-blur-sm animate-fade-in">
          <div className="bg-surface rounded-2xl w-full max-w-md shadow-2xl border border-white/10 overflow-hidden">
            {/* Header */}
            <div className="p-4 border-b border-white/10">
              <h2 className="text-lg font-semibold text-text">Leave Workout?</h2>
              <p className="text-sm text-text-muted mt-1">
                You've been working out for {formatTime(totalElapsedTime)}. Why are you leaving?
              </p>
            </div>

            {/* Exit Reason Options */}
            <div className="p-4 space-y-2 max-h-64 overflow-y-auto">
              {([
                { value: 'completed' as const, label: 'Finished workout', icon: '✅', description: "I'm done!" },
                { value: 'too_tired' as const, label: 'Too tired', icon: '😴', description: 'Need a break' },
                { value: 'out_of_time' as const, label: 'Out of time', icon: '⏰', description: 'Have to go' },
                { value: 'not_feeling_well' as const, label: 'Not feeling well', icon: '🤒', description: 'Feeling unwell' },
                { value: 'equipment_unavailable' as const, label: 'Equipment unavailable', icon: '🏋️', description: "Can't access equipment" },
                { value: 'injury' as const, label: 'Pain / injury', icon: '🩹', description: 'Experiencing discomfort' },
                { value: 'other' as const, label: 'Other reason', icon: '💭', description: 'Something else' },
              ]).map((option) => (
                <button
                  key={option.value}
                  onClick={() => setSelectedExitReason(option.value)}
                  className={`w-full p-3 rounded-xl flex items-center gap-3 transition-all ${
                    selectedExitReason === option.value
                      ? 'bg-primary/20 border-2 border-primary'
                      : 'bg-white/5 border-2 border-transparent hover:bg-white/10'
                  }`}
                >
                  <span className="text-2xl">{option.icon}</span>
                  <div className="text-left">
                    <div className="font-medium text-text">{option.label}</div>
                    <div className="text-xs text-text-muted">{option.description}</div>
                  </div>
                  {selectedExitReason === option.value && (
                    <svg className="w-5 h-5 text-primary ml-auto" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 13l4 4L19 7" />
                    </svg>
                  )}
                </button>
              ))}
            </div>

            {/* Notes input (shown for 'other' or always) */}
            {selectedExitReason && (
              <div className="px-4 pb-2">
                <textarea
                  value={exitNotes}
                  onChange={(e) => setExitNotes(e.target.value)}
                  placeholder="Add a note (optional)"
                  className="w-full px-3 py-2 bg-white/5 border border-white/10 rounded-lg text-text text-sm placeholder:text-text-muted resize-none focus:outline-none focus:border-primary/50"
                  rows={2}
                />
              </div>
            )}

            {/* Progress Summary */}
            <div className="px-4 pb-4">
              <div className="bg-white/5 rounded-lg p-3 flex items-center justify-between text-sm">
                <span className="text-text-muted">Progress</span>
                <div className="flex items-center gap-3">
                  <span className="text-text">
                    {Array.from(exerciseSets.entries()).filter(
                      ([, sets]) => sets.length > 0 && sets.every(s => s.isCompleted)
                    ).length} / {workout?.exercises?.length || 0} exercises
                  </span>
                  <span className="text-text-muted">|</span>
                  <span className="text-text">
                    {Array.from(exerciseSets.values()).flat().filter(s => s.isCompleted).length} sets
                  </span>
                </div>
              </div>
            </div>

            {/* Action Buttons */}
            <div className="p-4 border-t border-white/10 flex gap-3">
              <button
                onClick={() => setShowExitModal(false)}
                className="flex-1 py-3 px-4 bg-white/10 hover:bg-white/15 rounded-xl font-medium text-text transition-colors"
              >
                Keep Going
              </button>
              <button
                onClick={handleConfirmExit}
                disabled={!selectedExitReason || isExiting}
                className="flex-1 py-3 px-4 bg-red-500/80 hover:bg-red-500 rounded-xl font-medium text-white transition-colors disabled:opacity-50 disabled:cursor-not-allowed flex items-center justify-center gap-2"
              >
                {isExiting ? (
                  <>
                    <div className="w-4 h-4 border-2 border-white border-t-transparent rounded-full animate-spin" />
                    Saving...
                  </>
                ) : (
                  'Leave Workout'
                )}
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Workout Feedback Modal */}
      <WorkoutFeedbackModal
        isOpen={showFeedbackModal}
        onClose={handleFeedbackClose}
        workoutId={id!}
        userId={String(user?.id || '')}
        exercises={workout?.exercises?.map(ex => ({ name: ex.name })) || []}
        onFeedbackSubmitted={handleFeedbackClose}
      />
    </div>
  );
}
