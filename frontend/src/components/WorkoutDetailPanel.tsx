import { useEffect, useState } from 'react';
import { createPortal } from 'react-dom';
import { useNavigate } from 'react-router-dom';
import { useQuery, useMutation } from '@tanstack/react-query';
import { motion, AnimatePresence } from 'framer-motion';
import { getWorkout, deleteWorkout, getWorkoutWarmup, getWorkoutStretches, getWorkoutAISummary, type WarmupResponse, type StretchResponse } from '../api/client';
import { useAppStore } from '../store';
import type { Workout, WorkoutExercise } from '../types';
import { GlassCard, GlassButton } from './ui';

interface WorkoutDetailPanelProps {
  workoutId: string | null;
  onClose: () => void;
  onSelectExercise?: (exercise: WorkoutExercise) => void;
}

export default function WorkoutDetailPanel({ workoutId, onClose, onSelectExercise }: WorkoutDetailPanelProps) {
  const navigate = useNavigate();
  const { setCurrentWorkout, removeWorkout, setActiveWorkoutId } = useAppStore();

  // State for warmups and stretches
  const [warmup, setWarmup] = useState<WarmupResponse | null>(null);
  const [stretches, setStretches] = useState<StretchResponse | null>(null);
  const [loadingWarmupStretches, setLoadingWarmupStretches] = useState(false);
  const [warmupExpanded, setWarmupExpanded] = useState(false);
  const [stretchesExpanded, setStretchesExpanded] = useState(false);

  // State for AI summary modal
  const [showAISummary, setShowAISummary] = useState(false);
  const [aiSummary, setAiSummary] = useState<string | null>(null);
  const [loadingAISummary, setLoadingAISummary] = useState(false);

  const { data: workout, isLoading } = useQuery<Workout>({
    queryKey: ['workout', workoutId],
    queryFn: () => getWorkout(workoutId!),
    enabled: !!workoutId,
  });

  useEffect(() => {
    if (workout) {
      setCurrentWorkout(workout);
    }
  }, [workout, setCurrentWorkout]);

  // Reset expanded states when workout changes
  useEffect(() => {
    setWarmupExpanded(false);
    setStretchesExpanded(false);
    setWarmup(null);
    setStretches(null);
    setShowAISummary(false);
    setAiSummary(null);
  }, [workoutId]);

  // Handler for fetching AI summary
  const handleGetAISummary = async () => {
    if (!workoutId) return;

    setShowAISummary(true);
    if (aiSummary) return; // Already fetched

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

  // Fetch warmups and stretches when workout loads (they should already exist from backend)
  useEffect(() => {
    const fetchWarmupAndStretches = async () => {
      if (!workoutId) return;

      setLoadingWarmupStretches(true);
      try {
        const [warmupData, stretchData] = await Promise.all([
          getWorkoutWarmup(workoutId),
          getWorkoutStretches(workoutId)
        ]);

        // Set whatever data exists - don't generate on-demand
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

  // Handle exercise click - pass to parent if callback provided
  const handleExerciseClick = (exercise: WorkoutExercise) => {
    if (onSelectExercise) {
      onSelectExercise(exercise);
    }
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
            style={{
              boxShadow: '0 0 30px rgba(6, 182, 212, 0.2), 0 10px 30px rgba(0,0,0,0.2)',
            }}
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

          {/* Action Buttons */}
          {!isCompleted && (
            <div className="flex gap-2">
              <GlassButton
                variant="primary"
                onClick={handleStartWorkout}
                fullWidth
                size="sm"
                icon={
                  <svg className="w-4 h-4" fill="currentColor" viewBox="0 0 24 24">
                    <path d="M8 5v14l11-7z" />
                  </svg>
                }
              >
                Start
              </GlassButton>
              <GlassButton
                variant="secondary"
                onClick={() => navigate('/chat')}
                fullWidth
                size="sm"
                icon={
                  <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 3v4M3 5h4M6 17v4m-2-2h4m5-16l2.286 6.857L21 12l-5.714 2.143L13 21l-2.286-6.857L5 12l5.714-2.143L13 3z" />
                  </svg>
                }
              >
                Modify
              </GlassButton>
            </div>
          )}

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
              <svg
                className={`w-4 h-4 text-text-secondary transition-transform duration-200 ${warmupExpanded ? 'rotate-180' : ''}`}
                fill="none"
                stroke="currentColor"
                viewBox="0 0 24 24"
              >
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 9l-7 7-7-7" />
              </svg>
            </button>

            {warmupExpanded && (
              <div className="mt-3">
                {loadingWarmupStretches ? (
                  <div className="flex items-center justify-center py-3">
                    <div className="flex items-center gap-2 text-text-secondary">
                      <div className="w-4 h-4 border-2 border-orange-400 border-t-transparent rounded-full animate-spin" />
                      <span className="text-xs">Loading...</span>
                    </div>
                  </div>
                ) : warmup?.exercises_json?.length ? (
                  <div className="space-y-1.5">
                    {warmup.exercises_json.map((exercise, index) => (
                      <div
                        key={index}
                        className="p-2 bg-orange-500/5 rounded-lg border border-orange-500/20"
                      >
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

          {/* Exercises */}
          <GlassCard className="p-4">
            <div className="flex items-center gap-2 mb-3">
              <div className="p-1.5 bg-primary/20 rounded-lg text-primary">
                <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2" />
                </svg>
              </div>
              <div>
                <h2 className="text-sm font-semibold text-text">Exercises</h2>
                <p className="text-xs text-text-secondary">{workout.exercises.length} exercises</p>
              </div>
            </div>

            <div className="space-y-2">
              {workout.exercises.map((exercise, index) => (
                <motion.div
                  key={index}
                  onClick={() => handleExerciseClick(exercise)}
                  className="p-3 bg-white/5 rounded-xl border border-white/10 cursor-pointer group hover:bg-white/10 hover:border-primary/30 transition-all"
                  whileHover={{ scale: 1.01 }}
                  whileTap={{ scale: 0.99 }}
                >
                  <div className="flex justify-between items-start">
                    <div className="flex-1">
                      <div className="flex items-center gap-2">
                        <span className="w-5 h-5 bg-primary/20 text-primary rounded flex items-center justify-center text-xs font-bold">
                          {index + 1}
                        </span>
                        <h3 className="font-medium text-text text-sm">{exercise.name}</h3>
                        {/* Play icon indicator */}
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
                    <div className="text-xs text-text-muted bg-white/5 px-2 py-0.5 rounded border border-white/10">
                      {exercise.rest_seconds}s rest
                    </div>
                  </div>
                </motion.div>
              ))}
            </div>
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
              <svg
                className={`w-4 h-4 text-text-secondary transition-transform duration-200 ${stretchesExpanded ? 'rotate-180' : ''}`}
                fill="none"
                stroke="currentColor"
                viewBox="0 0 24 24"
              >
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 9l-7 7-7-7" />
              </svg>
            </button>

            {stretchesExpanded && (
              <div className="mt-3">
                {loadingWarmupStretches ? (
                  <div className="flex items-center justify-center py-3">
                    <div className="flex items-center gap-2 text-text-secondary">
                      <div className="w-4 h-4 border-2 border-green-400 border-t-transparent rounded-full animate-spin" />
                      <span className="text-xs">Loading...</span>
                    </div>
                  </div>
                ) : stretches?.exercises_json?.length ? (
                  <div className="space-y-1.5">
                    {stretches.exercises_json.map((stretch, index) => (
                      <div
                        key={index}
                        className="p-2 bg-green-500/5 rounded-lg border border-green-500/20"
                      >
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

    {/* Workout Summary Modal - Portal to body for proper z-index */}
    {createPortal(
      <AnimatePresence>
        {showAISummary && (
          <>
            {/* Backdrop */}
            <motion.div
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              exit={{ opacity: 0 }}
              className="fixed inset-0 bg-black/50 backdrop-blur-sm z-[9999]"
              onClick={() => setShowAISummary(false)}
            />

            {/* Centered Compact Modal */}
            <motion.div
              initial={{ opacity: 0, scale: 0.95, y: 10 }}
              animate={{ opacity: 1, scale: 1, y: 0 }}
              exit={{ opacity: 0, scale: 0.95, y: 10 }}
              transition={{ type: 'spring', damping: 25, stiffness: 400 }}
              className="fixed z-[9999] top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-[90vw] max-w-lg max-h-[70vh] overflow-hidden rounded-2xl bg-surface border border-white/10"
              style={{ boxShadow: '0 25px 50px -12px rgba(0,0,0,0.5)' }}
            >
              {/* Header */}
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

              {/* Content */}
              <div className="px-5 py-4 overflow-y-auto max-h-[calc(70vh-120px)]">
                {loadingAISummary ? (
                  <div className="flex flex-col items-center justify-center py-12">
                    <div className="w-12 h-12 border-3 border-secondary border-t-transparent rounded-full animate-spin mb-4" />
                    <p className="text-text-secondary">Generating AI summary...</p>
                    <p className="text-xs text-text-muted mt-1">Analyzing your workout...</p>
                  </div>
                ) : aiSummary ? (
                  <div className="space-y-4">
                    {/* Parse and render the markdown summary */}
                    {aiSummary.split('\n').map((line, index) => {
                      // Handle "Today's Intention:" header
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

                      // Handle exercise bullet points with bold names
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

                      // Handle regular bullet points
                      if (line.startsWith('- ') || line.startsWith('• ')) {
                        return (
                          <div key={index} className="flex items-start gap-2 text-text-secondary">
                            <span className="text-primary mt-1">•</span>
                            <span>{line.replace(/^[-•]\s*/, '')}</span>
                          </div>
                        );
                      }

                      // Handle section headers
                      if (line.startsWith('##')) {
                        return (
                          <h3 key={index} className="text-md font-bold text-text mt-4">
                            {line.replace(/^#+\s*/, '')}
                          </h3>
                        );
                      }

                      // Regular text
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

              {/* Footer with powered by */}
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
