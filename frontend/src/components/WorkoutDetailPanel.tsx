import { useEffect, useState, useCallback } from 'react';
import { createPortal } from 'react-dom';
import { useNavigate } from 'react-router-dom';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { motion, AnimatePresence, Reorder } from 'framer-motion';
import {
  getWorkout, deleteWorkout, getWorkoutWarmup, getWorkoutStretches, getWorkoutAISummary,
  updateWorkoutExercises, updateWarmupExercises, updateStretchExercises,
  type WarmupResponse, type StretchResponse, type WorkoutExerciseItem, type WarmupExerciseItem, type StretchExerciseItem
} from '../api/client';
import { useAppStore } from '../store';
import type { Workout, WorkoutExercise } from '../types';
import { GlassCard, GlassButton } from './ui';
import ExerciseLibraryModal from './ExerciseLibraryModal';
import ExerciseSwapModal from './ExerciseSwapModal';
import type { LibraryExercise } from '../api/client';

interface WorkoutDetailPanelProps {
  workoutId: string | null;
  onClose: () => void;
  onSelectExercise?: (exercise: WorkoutExercise) => void;
}

// Editable exercise item for drag-and-drop
interface EditableExercise {
  id: string;
  name: string;
  sets: number;
  reps: number;
  weight?: number;
  rest_seconds: number;
  target_muscles?: string[];
  equipment?: string;
}

export default function WorkoutDetailPanel({ workoutId, onClose, onSelectExercise }: WorkoutDetailPanelProps) {
  const navigate = useNavigate();
  const queryClient = useQueryClient();
  const { setCurrentWorkout, removeWorkout, setActiveWorkoutId } = useAppStore();

  // Edit mode state
  const [editMode, setEditMode] = useState(false);
  const [editedExercises, setEditedExercises] = useState<EditableExercise[]>([]);
  const [showAddExerciseModal, setShowAddExerciseModal] = useState(false);
  const [saving, setSaving] = useState(false);

  // State for warmups and stretches
  const [warmup, setWarmup] = useState<WarmupResponse | null>(null);
  const [stretches, setStretches] = useState<StretchResponse | null>(null);
  const [loadingWarmupStretches, setLoadingWarmupStretches] = useState(false);
  const [warmupExpanded, setWarmupExpanded] = useState(false);
  const [stretchesExpanded, setStretchesExpanded] = useState(false);
  const [warmupEditMode, setWarmupEditMode] = useState(false);
  const [stretchesEditMode, setStretchesEditMode] = useState(false);
  const [editedWarmup, setEditedWarmup] = useState<WarmupExerciseItem[]>([]);
  const [editedStretches, setEditedStretches] = useState<StretchExerciseItem[]>([]);

  // State for AI summary modal
  const [showAISummary, setShowAISummary] = useState(false);
  const [aiSummary, setAiSummary] = useState<string | null>(null);
  const [loadingAISummary, setLoadingAISummary] = useState(false);

  // State for exercise swap modal
  const [showSwapModal, setShowSwapModal] = useState(false);
  const [swapExerciseIndex, setSwapExerciseIndex] = useState<number>(-1);
  const [swapExercise, setSwapExercise] = useState<WorkoutExercise | null>(null);

  const { data: workout, isLoading, refetch } = useQuery<Workout>({
    queryKey: ['workout', workoutId],
    queryFn: () => getWorkout(workoutId!),
    enabled: !!workoutId,
  });

  useEffect(() => {
    if (workout) {
      setCurrentWorkout(workout);
    }
  }, [workout, setCurrentWorkout]);

  // Reset states when workout changes
  useEffect(() => {
    setWarmupExpanded(false);
    setStretchesExpanded(false);
    setWarmup(null);
    setStretches(null);
    setShowAISummary(false);
    setAiSummary(null);
    setEditMode(false);
    setWarmupEditMode(false);
    setStretchesEditMode(false);
  }, [workoutId]);

  // Initialize edited exercises when entering edit mode
  useEffect(() => {
    if (editMode && workout) {
      setEditedExercises(workout.exercises.map((ex, idx) => ({
        id: `ex-${idx}-${ex.name}`,
        name: ex.name,
        sets: ex.sets,
        reps: ex.reps,
        weight: ex.weight,
        rest_seconds: ex.rest_seconds || 60,
        muscle_group: ex.muscle_group,
        equipment: ex.equipment,
      })));
    }
  }, [editMode, workout]);

  // Initialize edited warmup/stretches when entering edit mode
  useEffect(() => {
    if (warmupEditMode && warmup?.exercises_json) {
      setEditedWarmup(warmup.exercises_json.map(ex => ({
        name: ex.name,
        sets: ex.sets,
        reps: ex.reps,
        duration_seconds: ex.duration_seconds,
        rest_seconds: ex.rest_seconds,
        equipment: ex.equipment || 'none',
        muscle_group: ex.muscle_group || '',
        notes: ex.notes,
      })));
    }
  }, [warmupEditMode, warmup]);

  useEffect(() => {
    if (stretchesEditMode && stretches?.exercises_json) {
      setEditedStretches(stretches.exercises_json.map(ex => ({
        name: ex.name,
        sets: ex.sets || 1,
        reps: ex.reps || 1,
        duration_seconds: ex.duration_seconds || 30,
        rest_seconds: ex.rest_seconds || 0,
        equipment: ex.equipment || 'none',
        muscle_group: ex.muscle_group || '',
        notes: ex.notes,
      })));
    }
  }, [stretchesEditMode, stretches]);

  // Handler for fetching AI summary
  const handleGetAISummary = async () => {
    if (!workoutId) return;
    setShowAISummary(true);
    if (aiSummary) return;

    setLoadingAISummary(true);
    try {
      const summary = await getWorkoutAISummary(workoutId);
      setAiSummary(summary);
    } catch (error) {
      console.error('Error fetching AI summary:', error);
      setAiSummary('Unable to generate summary. Please try again.');
    } finally {
      setLoadingAISummary(false);
    }
  };

  // Fetch warmups and stretches when workout loads
  useEffect(() => {
    const fetchWarmupAndStretches = async () => {
      if (!workoutId) return;
      setLoadingWarmupStretches(true);
      try {
        const [warmupData, stretchData] = await Promise.all([
          getWorkoutWarmup(workoutId),
          getWorkoutStretches(workoutId)
        ]);
        setWarmup(warmupData);
        setStretches(stretchData);
      } catch (error) {
        console.error('Error fetching warmup/stretches:', error);
      } finally {
        setLoadingWarmupStretches(false);
      }
    };

    if (workout) {
      fetchWarmupAndStretches();
    }
  }, [workoutId, workout]);

  const deleteMutation = useMutation({
    mutationFn: () => deleteWorkout(workoutId!),
    onSuccess: () => {
      removeWorkout(workoutId!);
      onClose();
    },
  });

  const handleStartWorkout = () => {
    if (workout) {
      setActiveWorkoutId(workout.id);
      navigate(`/workout/${workout.id}/active`);
    }
  };

  // Handle exercise click
  const handleExerciseClick = (exercise: WorkoutExercise) => {
    if (onSelectExercise && !editMode) {
      onSelectExercise(exercise);
    }
  };

  // Save exercise changes
  const handleSaveExercises = async () => {
    if (!workoutId) return;
    setSaving(true);
    try {
      const exercises: WorkoutExerciseItem[] = editedExercises.map(ex => ({
        name: ex.name,
        sets: ex.sets,
        reps: ex.reps,
        weight: ex.weight,
        rest_seconds: ex.rest_seconds,
        target_muscles: ex.target_muscles,
        equipment: ex.equipment,
      }));
      await updateWorkoutExercises(workoutId, exercises);
      await refetch();
      queryClient.invalidateQueries({ queryKey: ['workouts'] });
      setEditMode(false);
    } catch (error) {
      console.error('Error saving exercises:', error);
    } finally {
      setSaving(false);
    }
  };

  // Save warmup changes
  const handleSaveWarmup = async () => {
    if (!workoutId) return;
    setSaving(true);
    try {
      await updateWarmupExercises(workoutId, editedWarmup);
      const warmupData = await getWorkoutWarmup(workoutId);
      setWarmup(warmupData);
      setWarmupEditMode(false);
    } catch (error) {
      console.error('Error saving warmup:', error);
    } finally {
      setSaving(false);
    }
  };

  // Save stretches changes
  const handleSaveStretches = async () => {
    if (!workoutId) return;
    setSaving(true);
    try {
      await updateStretchExercises(workoutId, editedStretches);
      const stretchData = await getWorkoutStretches(workoutId);
      setStretches(stretchData);
      setStretchesEditMode(false);
    } catch (error) {
      console.error('Error saving stretches:', error);
    } finally {
      setSaving(false);
    }
  };

  // Remove exercise
  const handleRemoveExercise = (id: string) => {
    setEditedExercises(prev => prev.filter(ex => ex.id !== id));
  };

  // Add exercises from library
  const handleAddExercises = useCallback((exercises: Array<{ exercise: { name: string; body_part: string; equipment?: string }; sets: number; reps: number }>) => {
    const newExercises: EditableExercise[] = exercises.map((item, idx) => ({
      id: `new-${Date.now()}-${idx}`,
      name: item.exercise.name,
      sets: item.sets,
      reps: item.reps,
      rest_seconds: 60,
      target_muscles: [item.exercise.body_part],
      equipment: item.exercise.equipment,
    }));
    setEditedExercises(prev => [...prev, ...newExercises]);
  }, []);

  // Handle opening swap modal for an exercise
  const handleOpenSwapModal = (exercise: WorkoutExercise, index: number) => {
    setSwapExercise(exercise);
    setSwapExerciseIndex(index);
    setShowSwapModal(true);
  };

  // Handle swapping an exercise
  const handleSwapExercise = async (newExercise: LibraryExercise, sets: number, reps: number) => {
    if (!workoutId || !workout || swapExerciseIndex < 0) return;

    setSaving(true);
    try {
      // Create the new exercises array with the swap
      const updatedExercises: WorkoutExerciseItem[] = workout.exercises.map((ex, idx) => {
        if (idx === swapExerciseIndex) {
          return {
            name: newExercise.name,
            sets: sets,
            reps: reps,
            weight: ex.weight,
            rest_seconds: ex.rest_seconds || 60,
            target_muscles: [newExercise.body_part],
            equipment: newExercise.equipment,
          };
        }
        return {
          name: ex.name,
          sets: ex.sets,
          reps: ex.reps,
          weight: ex.weight,
          rest_seconds: ex.rest_seconds || 60,
          target_muscles: ex.muscle_group ? [ex.muscle_group] : undefined,
          equipment: ex.equipment,
        };
      });

      // Save to database
      await updateWorkoutExercises(workoutId, updatedExercises);
      await refetch();
      queryClient.invalidateQueries({ queryKey: ['workouts'] });

      // Close modal
      setShowSwapModal(false);
      setSwapExercise(null);
      setSwapExerciseIndex(-1);
    } catch (error) {
      console.error('Error swapping exercise:', error);
    } finally {
      setSaving(false);
    }
  };

  // Update exercise field
  const handleUpdateExercise = (id: string, field: keyof EditableExercise, value: number | string) => {
    setEditedExercises(prev =>
      prev.map(ex => ex.id === id ? { ...ex, [field]: value } : ex)
    );
  };

  // Empty state when no workout selected
  if (!workoutId) {
    return (
      <div className="h-full flex items-center justify-center">
        <div className="text-center p-8">
          <div className="w-20 h-20 bg-white/5 rounded-2xl flex items-center justify-center mx-auto mb-4">
            <svg className="w-10 h-10 text-text-muted" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M15 15l-2 5L9 9l11 4-5 2zm0 0l5 5M7.188 2.239l.777 2.897M5.136 7.965l-2.898-.777M13.95 4.05l-2.122 2.122m-5.657 5.656l-2.12 2.122" />
            </svg>
          </div>
          <h3 className="text-lg font-semibold text-text mb-2">Select a Workout</h3>
          <p className="text-sm text-text-secondary max-w-xs">
            Click on a workout from the schedule to view its details here
          </p>
        </div>
      </div>
    );
  }

  if (isLoading) {
    return (
      <div className="flex items-center justify-center h-64">
        <div className="flex flex-col items-center gap-3">
          <div className="w-10 h-10 border-3 border-primary border-t-transparent rounded-full animate-spin" />
          <p className="text-text-secondary">Loading workout...</p>
        </div>
      </div>
    );
  }

  if (!workout) {
    return (
      <div className="flex items-center justify-center h-64">
        <div className="text-center">
          <div className="w-16 h-16 bg-white/5 rounded-2xl flex items-center justify-center mx-auto mb-4">
            <svg className="w-8 h-8 text-text-muted" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9.172 16.172a4 4 0 015.656 0M9 10h.01M15 10h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
            </svg>
          </div>
          <p className="text-text-secondary mb-4">Workout not found</p>
          <button onClick={onClose} className="text-primary font-semibold hover:underline">
            Close panel
          </button>
        </div>
      </div>
    );
  }

  const isCompleted = !!workout.completed_at;

  return (
    <>
    <AnimatePresence mode="wait">
      <motion.div
        key={workoutId}
        initial={{ opacity: 0, x: 20 }}
        animate={{ opacity: 1, x: 0 }}
        exit={{ opacity: 0, x: -20 }}
        transition={{ duration: 0.2 }}
        className="h-full overflow-y-auto"
      >
        <div className="space-y-4 p-1">
          {/* Header with close button */}
          <div className="flex items-center justify-between mb-2">
            <button
              onClick={onClose}
              className="p-2 hover:bg-white/10 rounded-xl transition-colors text-text-secondary hover:text-text"
            >
              <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
              </svg>
            </button>
            <button
              onClick={() => navigate(`/workout/${workout.id}`)}
              className="text-sm text-primary hover:underline flex items-center gap-1"
            >
              Open full page
              <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M10 6H6a2 2 0 00-2 2v10a2 2 0 002 2h10a2 2 0 002-2v-4M14 4h6m0 0v6m0-6L10 14" />
              </svg>
            </button>
          </div>

          {/* Workout Header Card */}
          <div
            className="relative overflow-hidden rounded-2xl p-5 bg-gradient-to-br from-primary to-secondary"
            style={{ boxShadow: '0 0 30px rgba(6, 182, 212, 0.2), 0 10px 30px rgba(0,0,0,0.2)' }}
          >
            <h1 className="text-xl font-bold text-white">{workout.name}</h1>
            <div className="flex flex-wrap gap-2 mt-3">
              <span className="px-2.5 py-1 bg-white/20 backdrop-blur rounded-lg text-white text-xs capitalize">
                {workout.type}
              </span>
              <span className="px-2.5 py-1 bg-white/20 backdrop-blur rounded-lg text-white text-xs capitalize">
                {workout.difficulty}
              </span>
              <span className="px-2.5 py-1 bg-white/20 backdrop-blur rounded-lg text-white text-xs flex items-center gap-1">
                <svg className="w-3 h-3" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z" />
                </svg>
                {workout.duration_minutes} min
              </span>
            </div>
            {isCompleted && (
              <div className="mt-3 inline-flex items-center gap-1.5 px-2.5 py-1 bg-accent/30 backdrop-blur rounded-lg text-white text-xs">
                <svg className="w-3.5 h-3.5 text-accent" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2.5} d="M5 13l4 4L19 7" />
                </svg>
                Completed
              </div>
            )}
          </div>

          {/* Completion Status Banner */}
          {isCompleted && (
            <div className="p-3 bg-accent/10 border border-accent/30 rounded-xl">
              <div className="flex items-center gap-3">
                <div className="p-2 bg-accent/20 rounded-lg">
                  <svg className="w-5 h-5 text-accent" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2.5} d="M5 13l4 4L19 7" />
                  </svg>
                </div>
                <div className="flex-1">
                  <p className="text-sm font-semibold text-accent">Workout Completed!</p>
                  <p className="text-xs text-text-muted">
                    {workout.completed_at && `Finished ${new Date(workout.completed_at).toLocaleDateString()}`}
                  </p>
                </div>
              </div>
            </div>
          )}

          {/* Action Buttons */}
          <div className="flex gap-2">
            <GlassButton
              variant={isCompleted ? 'secondary' : 'primary'}
              onClick={handleStartWorkout}
              fullWidth
              size="sm"
              icon={
                isCompleted ? (
                  <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15" />
                  </svg>
                ) : (
                  <svg className="w-4 h-4" fill="currentColor" viewBox="0 0 24 24">
                    <path d="M8 5v14l11-7z" />
                  </svg>
                )
              }
            >
              {isCompleted ? 'Restart' : 'Start'}
            </GlassButton>
            <GlassButton
              variant="secondary"
              onClick={() => setEditMode(!editMode)}
              fullWidth
              size="sm"
              icon={
                <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z" />
                </svg>
              }
            >
              {editMode ? 'Cancel' : 'Edit'}
            </GlassButton>
          </div>

          {/* Workout Summary Button */}
          <motion.button
            onClick={handleGetAISummary}
            className="w-full p-3 bg-gradient-to-r from-secondary/20 to-primary/20 rounded-xl border border-secondary/30 hover:border-secondary/50 transition-all group flex items-center gap-3"
            whileHover={{ scale: 1.01 }}
            whileTap={{ scale: 0.99 }}
          >
            <div className="p-2 bg-secondary/20 rounded-lg text-secondary group-hover:bg-secondary/30 transition-colors">
              <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
              </svg>
            </div>
            <div className="flex-1 text-left">
              <h3 className="text-sm font-semibold text-text">Workout Summary</h3>
              <p className="text-xs text-text-secondary">Tap to see today's intention & exercise benefits</p>
            </div>
            <svg className="w-4 h-4 text-text-secondary group-hover:text-secondary transition-colors" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 5l7 7-7 7" />
            </svg>
          </motion.button>

          {/* Warmup Section */}
          <GlassCard className="p-4">
            <button
              onClick={() => setWarmupExpanded(!warmupExpanded)}
              className="w-full flex items-center justify-between cursor-pointer"
            >
              <div className="flex items-center gap-2">
                <div className="p-1.5 bg-orange-500/20 rounded-lg text-orange-400">
                  <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M17.657 18.657A8 8 0 016.343 7.343S7 9 9 10c0-2 .5-5 2.986-7C14 5 16.09 5.777 17.656 7.343A7.975 7.975 0 0120 13a7.975 7.975 0 01-2.343 5.657z" />
                  </svg>
                </div>
                <div className="text-left">
                  <h2 className="text-sm font-semibold text-text">Warm-up</h2>
                  <p className="text-xs text-text-secondary">
                    {loadingWarmupStretches
                      ? 'Loading...'
                      : warmup?.exercises_json?.length
                        ? `${warmup.exercises_json.length} exercises`
                        : 'No warmup'}
                  </p>
                </div>
              </div>
              <div className="flex items-center gap-2">
                {warmupExpanded && warmup?.exercises_json?.length && !warmupEditMode && (
                  <button
                    onClick={(e) => { e.stopPropagation(); setWarmupEditMode(true); setWarmupExpanded(true); }}
                    className="p-1 text-text-muted hover:text-orange-400 transition-colors"
                  >
                    <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z" />
                    </svg>
                  </button>
                )}
                <svg
                  className={`w-4 h-4 text-text-secondary transition-transform duration-200 ${warmupExpanded ? 'rotate-180' : ''}`}
                  fill="none"
                  stroke="currentColor"
                  viewBox="0 0 24 24"
                >
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 9l-7 7-7-7" />
                </svg>
              </div>
            </button>

            {warmupExpanded && (
              <div className="mt-3">
                {warmupEditMode ? (
                  <div className="space-y-2">
                    <Reorder.Group axis="y" values={editedWarmup} onReorder={setEditedWarmup} className="space-y-2">
                      {editedWarmup.map((exercise, index) => (
                        <Reorder.Item key={`warmup-${index}-${exercise.name}`} value={exercise}>
                          <div className="p-2 bg-orange-500/10 rounded-lg border border-orange-500/30 cursor-grab active:cursor-grabbing">
                            <div className="flex items-center justify-between">
                              <div className="flex items-center gap-2">
                                <svg className="w-4 h-4 text-orange-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4 8h16M4 16h16" />
                                </svg>
                                <span className="text-text text-xs font-medium">{exercise.name}</span>
                              </div>
                              <button
                                onClick={() => setEditedWarmup(prev => prev.filter((_, i) => i !== index))}
                                className="p-1 text-red-400 hover:text-red-300"
                              >
                                <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" />
                                </svg>
                              </button>
                            </div>
                          </div>
                        </Reorder.Item>
                      ))}
                    </Reorder.Group>
                    <div className="flex gap-2 pt-2">
                      <button
                        onClick={() => setWarmupEditMode(false)}
                        className="flex-1 px-3 py-2 bg-white/10 text-text-secondary rounded-lg text-xs hover:bg-white/20"
                      >
                        Cancel
                      </button>
                      <button
                        onClick={handleSaveWarmup}
                        disabled={saving}
                        className="flex-1 px-3 py-2 bg-orange-500 text-white rounded-lg text-xs hover:bg-orange-600 disabled:opacity-50"
                      >
                        {saving ? 'Saving...' : 'Save'}
                      </button>
                    </div>
                  </div>
                ) : loadingWarmupStretches ? (
                  <div className="flex items-center justify-center py-3">
                    <div className="flex items-center gap-2 text-text-secondary">
                      <div className="w-4 h-4 border-2 border-orange-400 border-t-transparent rounded-full animate-spin" />
                      <span className="text-xs">Loading...</span>
                    </div>
                  </div>
                ) : warmup?.exercises_json?.length ? (
                  <div className="space-y-1.5">
                    {warmup.exercises_json.map((exercise, index) => (
                      <div key={index} className="p-2 bg-orange-500/5 rounded-lg border border-orange-500/20">
                        <div className="flex justify-between items-center">
                          <div className="flex items-center gap-2">
                            <span className="w-5 h-5 bg-orange-500/20 text-orange-400 rounded flex items-center justify-center text-xs font-bold">
                              {index + 1}
                            </span>
                            <span className="font-medium text-text text-xs">{exercise.name}</span>
                          </div>
                          <div className="text-xs text-text-secondary">
                            {exercise.duration_seconds && `${exercise.duration_seconds}s`}
                            {exercise.reps && `${exercise.reps} reps`}
                          </div>
                        </div>
                      </div>
                    ))}
                  </div>
                ) : (
                  <p className="text-xs text-text-muted text-center py-2">No warmup exercises</p>
                )}
              </div>
            )}
          </GlassCard>

          {/* Exercises Section */}
          <GlassCard className="p-4">
            <div className="flex items-center justify-between mb-3">
              <div className="flex items-center gap-2">
                <div className="p-1.5 bg-primary/20 rounded-lg text-primary">
                  <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2" />
                  </svg>
                </div>
                <div>
                  <h2 className="text-sm font-semibold text-text">Exercises</h2>
                  <p className="text-xs text-text-secondary">
                    {editMode ? editedExercises.length : workout.exercises.length} exercises
                  </p>
                </div>
              </div>
              {editMode && (
                <button
                  onClick={() => setShowAddExerciseModal(true)}
                  className="p-1.5 bg-primary/20 rounded-lg text-primary hover:bg-primary/30 transition-colors"
                >
                  <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 6v6m0 0v6m0-6h6m-6 0H6" />
                  </svg>
                </button>
              )}
            </div>

            {editMode ? (
              <div className="space-y-2">
                <Reorder.Group axis="y" values={editedExercises} onReorder={setEditedExercises} className="space-y-2">
                  {editedExercises.map((exercise) => (
                    <Reorder.Item key={exercise.id} value={exercise}>
                      <motion.div
                        className="p-3 bg-white/5 rounded-xl border border-white/10 cursor-grab active:cursor-grabbing"
                        layout
                      >
                        <div className="flex justify-between items-start">
                          <div className="flex items-center gap-2 flex-1">
                            <svg className="w-4 h-4 text-text-muted" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4 8h16M4 16h16" />
                            </svg>
                            <h3 className="font-medium text-text text-sm">{exercise.name}</h3>
                          </div>
                          <button
                            onClick={() => handleRemoveExercise(exercise.id)}
                            className="p-1 text-red-400 hover:text-red-300 transition-colors"
                          >
                            <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" />
                            </svg>
                          </button>
                        </div>
                        <div className="mt-2 flex gap-2 ml-6">
                          <div className="flex items-center gap-1">
                            <input
                              type="number"
                              value={exercise.sets}
                              onChange={(e) => handleUpdateExercise(exercise.id, 'sets', parseInt(e.target.value) || 1)}
                              className="w-12 px-2 py-1 bg-white/10 rounded text-text text-xs text-center"
                              min={1}
                            />
                            <span className="text-xs text-text-secondary">sets</span>
                          </div>
                          <div className="flex items-center gap-1">
                            <input
                              type="number"
                              value={exercise.reps}
                              onChange={(e) => handleUpdateExercise(exercise.id, 'reps', parseInt(e.target.value) || 1)}
                              className="w-12 px-2 py-1 bg-white/10 rounded text-text text-xs text-center"
                              min={1}
                            />
                            <span className="text-xs text-text-secondary">reps</span>
                          </div>
                        </div>
                      </motion.div>
                    </Reorder.Item>
                  ))}
                </Reorder.Group>

                {/* Save/Cancel buttons */}
                <div className="flex gap-2 pt-2">
                  <button
                    onClick={() => setEditMode(false)}
                    className="flex-1 px-3 py-2 bg-white/10 text-text-secondary rounded-lg text-sm hover:bg-white/20 transition-colors"
                  >
                    Cancel
                  </button>
                  <button
                    onClick={handleSaveExercises}
                    disabled={saving}
                    className="flex-1 px-3 py-2 bg-primary text-white rounded-lg text-sm hover:bg-primary/80 transition-colors disabled:opacity-50"
                  >
                    {saving ? 'Saving...' : 'Save Changes'}
                  </button>
                </div>
              </div>
            ) : (
              <div className="space-y-2">
                {workout.exercises.map((exercise, index) => (
                  <motion.div
                    key={index}
                    className="p-3 bg-white/5 rounded-xl border border-white/10 group hover:bg-white/10 hover:border-primary/30 transition-all"
                    whileHover={{ scale: 1.01 }}
                  >
                    <div className="flex justify-between items-start">
                      <div
                        className="flex-1 cursor-pointer"
                        onClick={() => handleExerciseClick(exercise)}
                      >
                        <div className="flex items-center gap-2">
                          <span className="w-5 h-5 bg-primary/20 text-primary rounded flex items-center justify-center text-xs font-bold">
                            {index + 1}
                          </span>
                          <h3 className="font-medium text-text text-sm">{exercise.name}</h3>
                          <svg className="w-3.5 h-3.5 text-text-muted group-hover:text-primary transition-colors" fill="currentColor" viewBox="0 0 24 24">
                            <path d="M8 5v14l11-7z" />
                          </svg>
                        </div>
                        <div className="mt-1.5 flex flex-wrap gap-1.5 ml-7">
                          <span className="px-2 py-0.5 bg-white/5 text-text-secondary text-xs rounded border border-white/10">
                            {exercise.sets} sets
                          </span>
                          <span className="px-2 py-0.5 bg-white/5 text-text-secondary text-xs rounded border border-white/10">
                            {exercise.reps} reps
                          </span>
                          {exercise.weight && (
                            <span className="px-2 py-0.5 bg-accent/15 text-accent text-xs rounded border border-accent/30">
                              {exercise.weight} lbs
                            </span>
                          )}
                        </div>
                      </div>
                      <div className="flex items-center gap-2">
                        {/* Shuffle/Swap Button */}
                        {!isCompleted && (
                          <motion.button
                            onClick={(e) => {
                              e.stopPropagation();
                              handleOpenSwapModal(exercise, index);
                            }}
                            className="p-1.5 rounded-lg bg-secondary/10 text-secondary hover:bg-secondary/20 transition-colors opacity-0 group-hover:opacity-100"
                            whileHover={{ scale: 1.1 }}
                            whileTap={{ scale: 0.9 }}
                            title="Swap exercise"
                          >
                            <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M8 7h12m0 0l-4-4m4 4l-4 4m0 6H4m0 0l4 4m-4-4l4-4" />
                            </svg>
                          </motion.button>
                        )}
                        <div className="text-xs text-text-muted bg-white/5 px-2 py-0.5 rounded border border-white/10">
                          {exercise.rest_seconds}s rest
                        </div>
                      </div>
                    </div>
                  </motion.div>
                ))}
              </div>
            )}
          </GlassCard>

          {/* Stretches Section */}
          <GlassCard className="p-4">
            <button
              onClick={() => setStretchesExpanded(!stretchesExpanded)}
              className="w-full flex items-center justify-between cursor-pointer"
            >
              <div className="flex items-center gap-2">
                <div className="p-1.5 bg-green-500/20 rounded-lg text-green-400">
                  <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4.318 6.318a4.5 4.5 0 000 6.364L12 20.364l7.682-7.682a4.5 4.5 0 00-6.364-6.364L12 7.636l-1.318-1.318a4.5 4.5 0 00-6.364 0z" />
                  </svg>
                </div>
                <div className="text-left">
                  <h2 className="text-sm font-semibold text-text">Cool-down</h2>
                  <p className="text-xs text-text-secondary">
                    {loadingWarmupStretches
                      ? 'Loading...'
                      : stretches?.exercises_json?.length
                        ? `${stretches.exercises_json.length} stretches`
                        : 'No stretches'}
                  </p>
                </div>
              </div>
              <div className="flex items-center gap-2">
                {stretchesExpanded && stretches?.exercises_json?.length && !stretchesEditMode && (
                  <button
                    onClick={(e) => { e.stopPropagation(); setStretchesEditMode(true); setStretchesExpanded(true); }}
                    className="p-1 text-text-muted hover:text-green-400 transition-colors"
                  >
                    <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z" />
                    </svg>
                  </button>
                )}
                <svg
                  className={`w-4 h-4 text-text-secondary transition-transform duration-200 ${stretchesExpanded ? 'rotate-180' : ''}`}
                  fill="none"
                  stroke="currentColor"
                  viewBox="0 0 24 24"
                >
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 9l-7 7-7-7" />
                </svg>
              </div>
            </button>

            {stretchesExpanded && (
              <div className="mt-3">
                {stretchesEditMode ? (
                  <div className="space-y-2">
                    <Reorder.Group axis="y" values={editedStretches} onReorder={setEditedStretches} className="space-y-2">
                      {editedStretches.map((stretch, index) => (
                        <Reorder.Item key={`stretch-${index}-${stretch.name}`} value={stretch}>
                          <div className="p-2 bg-green-500/10 rounded-lg border border-green-500/30 cursor-grab active:cursor-grabbing">
                            <div className="flex items-center justify-between">
                              <div className="flex items-center gap-2">
                                <svg className="w-4 h-4 text-green-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4 8h16M4 16h16" />
                                </svg>
                                <span className="text-text text-xs font-medium">{stretch.name}</span>
                              </div>
                              <button
                                onClick={() => setEditedStretches(prev => prev.filter((_, i) => i !== index))}
                                className="p-1 text-red-400 hover:text-red-300"
                              >
                                <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" />
                                </svg>
                              </button>
                            </div>
                          </div>
                        </Reorder.Item>
                      ))}
                    </Reorder.Group>
                    <div className="flex gap-2 pt-2">
                      <button
                        onClick={() => setStretchesEditMode(false)}
                        className="flex-1 px-3 py-2 bg-white/10 text-text-secondary rounded-lg text-xs hover:bg-white/20"
                      >
                        Cancel
                      </button>
                      <button
                        onClick={handleSaveStretches}
                        disabled={saving}
                        className="flex-1 px-3 py-2 bg-green-500 text-white rounded-lg text-xs hover:bg-green-600 disabled:opacity-50"
                      >
                        {saving ? 'Saving...' : 'Save'}
                      </button>
                    </div>
                  </div>
                ) : loadingWarmupStretches ? (
                  <div className="flex items-center justify-center py-3">
                    <div className="flex items-center gap-2 text-text-secondary">
                      <div className="w-4 h-4 border-2 border-green-400 border-t-transparent rounded-full animate-spin" />
                      <span className="text-xs">Loading...</span>
                    </div>
                  </div>
                ) : stretches?.exercises_json?.length ? (
                  <div className="space-y-1.5">
                    {stretches.exercises_json.map((stretch, index) => (
                      <div key={index} className="p-2 bg-green-500/5 rounded-lg border border-green-500/20">
                        <div className="flex justify-between items-center">
                          <div className="flex items-center gap-2">
                            <span className="w-5 h-5 bg-green-500/20 text-green-400 rounded flex items-center justify-center text-xs font-bold">
                              {index + 1}
                            </span>
                            <span className="font-medium text-text text-xs">{stretch.name}</span>
                          </div>
                          <div className="text-xs text-text-secondary">
                            {stretch.duration_seconds && `${stretch.duration_seconds}s`}
                            {stretch.reps && `${stretch.reps} reps`}
                          </div>
                        </div>
                      </div>
                    ))}
                  </div>
                ) : (
                  <p className="text-xs text-text-muted text-center py-2">No stretches</p>
                )}
              </div>
            )}
          </GlassCard>

          {/* Notes */}
          {workout.notes && (
            <GlassCard className="p-4">
              <div className="flex items-center gap-2 mb-2">
                <svg className="w-4 h-4 text-text-secondary" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z" />
                </svg>
                <h2 className="font-semibold text-text text-sm">Notes</h2>
              </div>
              <p className="text-text-secondary text-xs">{workout.notes}</p>
            </GlassCard>
          )}

          {/* Delete Button */}
          <GlassButton
            variant="danger"
            onClick={() => {
              if (confirm('Are you sure you want to delete this workout?')) {
                deleteMutation.mutate();
              }
            }}
            disabled={deleteMutation.isPending}
            loading={deleteMutation.isPending}
            fullWidth
            size="sm"
            icon={
              <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" />
              </svg>
            }
          >
            Delete Workout
          </GlassButton>
        </div>
      </motion.div>
    </AnimatePresence>

    {/* Exercise Library Modal */}
    <ExerciseLibraryModal
      isOpen={showAddExerciseModal}
      onClose={() => setShowAddExerciseModal(false)}
      onAddExercises={handleAddExercises}
      existingExerciseNames={editedExercises.map(ex => ex.name)}
    />

    {/* Exercise Swap Modal */}
    <ExerciseSwapModal
      isOpen={showSwapModal}
      onClose={() => {
        setShowSwapModal(false);
        setSwapExercise(null);
        setSwapExerciseIndex(-1);
      }}
      currentExercise={swapExercise}
      onSwap={handleSwapExercise}
    />

    {/* Workout Summary Modal */}
    {createPortal(
      <AnimatePresence>
        {showAISummary && (
          <>
            <motion.div
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              exit={{ opacity: 0 }}
              className="fixed inset-0 bg-black/50 backdrop-blur-sm z-[9999]"
              onClick={() => setShowAISummary(false)}
            />
            <motion.div
              initial={{ opacity: 0, scale: 0.95, y: 10 }}
              animate={{ opacity: 1, scale: 1, y: 0 }}
              exit={{ opacity: 0, scale: 0.95, y: 10 }}
              transition={{ type: 'spring', damping: 25, stiffness: 400 }}
              className="fixed z-[9999] top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-[90vw] max-w-lg max-h-[70vh] overflow-hidden rounded-2xl bg-surface border border-white/10"
              style={{ boxShadow: '0 25px 50px -12px rgba(0,0,0,0.5)' }}
            >
              <div className="px-5 py-4 border-b border-white/10 flex items-center justify-between">
                <div className="flex items-center gap-3">
                  <div className="p-2 bg-gradient-to-br from-secondary/30 to-primary/30 rounded-xl">
                    <svg className="w-5 h-5 text-secondary" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
                    </svg>
                  </div>
                  <div>
                    <h2 className="text-base font-bold text-text">Workout Summary</h2>
                    <p className="text-xs text-text-secondary">{workout?.name}</p>
                  </div>
                </div>
                <button
                  onClick={() => setShowAISummary(false)}
                  className="p-1.5 hover:bg-white/10 rounded-lg transition-colors"
                >
                  <svg className="w-5 h-5 text-text-secondary" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
                  </svg>
                </button>
              </div>
              <div className="px-5 py-4 overflow-y-auto max-h-[calc(70vh-120px)]">
                {loadingAISummary ? (
                  <div className="flex flex-col items-center justify-center py-12">
                    <div className="w-12 h-12 border-3 border-secondary border-t-transparent rounded-full animate-spin mb-4" />
                    <p className="text-text-secondary">Generating AI summary...</p>
                    <p className="text-xs text-text-muted mt-1">Analyzing your workout...</p>
                  </div>
                ) : aiSummary ? (
                  <div className="space-y-4">
                    {aiSummary.split('\n').map((line, index) => {
                      if (line.includes("Today's Intention:") || line.includes("**Today's Intention:**")) {
                        return (
                          <div key={index} className="mb-4">
                            <h3 className="text-lg font-bold text-primary mb-2">Today's Intention</h3>
                            <p className="text-text-secondary">
                              {line.replace("**Today's Intention:**", '').replace("Today's Intention:", '').trim()}
                            </p>
                          </div>
                        );
                      }
                      if (line.startsWith('- **') || line.startsWith('• **')) {
                        const match = line.match(/[-•]\s*\*\*(.+?)\*\*[:\s]*(.+)/);
                        if (match) {
                          return (
                            <div key={index} className="p-3 bg-white/5 rounded-xl border border-white/10">
                              <div className="flex items-start gap-3">
                                <div className="p-1.5 bg-primary/20 rounded-lg text-primary mt-0.5">
                                  <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 13l4 4L19 7" />
                                  </svg>
                                </div>
                                <div>
                                  <h4 className="font-semibold text-text">{match[1]}</h4>
                                  <p className="text-sm text-text-secondary mt-1">{match[2]}</p>
                                </div>
                              </div>
                            </div>
                          );
                        }
                      }
                      if (line.startsWith('- ') || line.startsWith('• ')) {
                        return (
                          <div key={index} className="flex items-start gap-2 text-text-secondary">
                            <span className="text-primary mt-1">•</span>
                            <span>{line.replace(/^[-•]\s*/, '')}</span>
                          </div>
                        );
                      }
                      if (line.startsWith('##')) {
                        return (
                          <h3 key={index} className="text-md font-bold text-text mt-4">
                            {line.replace(/^#+\s*/, '')}
                          </h3>
                        );
                      }
                      if (line.trim()) {
                        return (
                          <p key={index} className="text-text-secondary">
                            {line.replace(/\*\*/g, '')}
                          </p>
                        );
                      }
                      return null;
                    })}
                  </div>
                ) : (
                  <div className="flex flex-col items-center justify-center py-12">
                    <div className="w-16 h-16 bg-white/5 rounded-2xl flex items-center justify-center mb-4">
                      <svg className="w-8 h-8 text-text-muted" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9.172 16.172a4 4 0 015.656 0M9 10h.01M15 10h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
                      </svg>
                    </div>
                    <p className="text-text-secondary">Unable to load summary</p>
                    <button
                      onClick={handleGetAISummary}
                      className="mt-3 text-primary hover:underline text-sm"
                    >
                      Try again
                    </button>
                  </div>
                )}
              </div>
              <div className="px-5 py-2.5 border-t border-white/10 flex items-center justify-center gap-2 text-xs text-text-muted">
                <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M13 10V3L4 14h7v7l9-11h-7z" />
                </svg>
                <span>Powered by AI Coach</span>
              </div>
            </motion.div>
          </>
        )}
      </AnimatePresence>,
      document.body
    )}
    </>
  );
}
