import { useEffect, useRef, useState } from 'react';
import { useParams, useNavigate, Link, useSearchParams } from 'react-router-dom';
import { useQuery, useMutation } from '@tanstack/react-query';
import { getWorkout, deleteWorkout, getWorkoutWarmup, getWorkoutStretches, type WarmupResponse, type StretchResponse } from '../api/client';
import { useAppStore } from '../store';
import type { Workout } from '../types';
import { GlassCard, GlassButton } from '../components/ui';
import { DashboardLayout } from '../components/layout';

export default function WorkoutDetails() {
  const { id } = useParams<{ id: string }>();
  const [searchParams] = useSearchParams();
  const navigate = useNavigate();
  const { setCurrentWorkout, removeWorkout, setActiveWorkoutId } = useAppStore();
  const autoStartHandled = useRef(false);

  // State for warmups and stretches
  const [warmup, setWarmup] = useState<WarmupResponse | null>(null);
  const [stretches, setStretches] = useState<StretchResponse | null>(null);
  const [loadingWarmupStretches, setLoadingWarmupStretches] = useState(false);
  const [warmupExpanded, setWarmupExpanded] = useState(false);
  const [stretchesExpanded, setStretchesExpanded] = useState(false);

  const { data: workout, isLoading } = useQuery<Workout>({
    queryKey: ['workout', id],
    queryFn: () => getWorkout(id!),
    enabled: !!id,
  });

  useEffect(() => {
    if (workout) {
      setCurrentWorkout(workout);
    }
  }, [workout, setCurrentWorkout]);

  // Fetch warmups and stretches when workout loads (they should already exist from backend)
  useEffect(() => {
    const fetchWarmupAndStretches = async () => {
      if (!id) return;

      setLoadingWarmupStretches(true);
      try {
        const [warmupData, stretchData] = await Promise.all([
          getWorkoutWarmup(id),
          getWorkoutStretches(id)
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
  }, [id, workout]);

  // Auto-start workout if ?start=true is in URL
  useEffect(() => {
    if (workout && !autoStartHandled.current && searchParams.get('start') === 'true' && !workout.completed_at) {
      autoStartHandled.current = true;
      setActiveWorkoutId(workout.id);
      navigate(`/workout/${workout.id}/active`, { replace: true });
    }
  }, [workout, searchParams, setActiveWorkoutId, navigate]);

  const deleteMutation = useMutation({
    mutationFn: () => deleteWorkout(id!),
    onSuccess: () => {
      removeWorkout(id!);
      navigate('/');
    },
  });

  const handleStartWorkout = () => {
    if (workout) {
      setActiveWorkoutId(workout.id);
      navigate(`/workout/${workout.id}/active`);
    }
  };

  if (isLoading) {
    return (
      <DashboardLayout>
        <div className="flex items-center justify-center min-h-[60vh]">
          <div className="flex flex-col items-center gap-3">
            <div className="w-10 h-10 border-3 border-primary border-t-transparent rounded-full animate-spin" />
            <p className="text-text-secondary">Loading workout...</p>
          </div>
        </div>
      </DashboardLayout>
    );
  }

  if (!workout) {
    return (
      <DashboardLayout>
        <div className="flex items-center justify-center min-h-[60vh]">
          <div className="text-center">
            <div className="w-16 h-16 bg-white/5 rounded-2xl flex items-center justify-center mx-auto mb-4">
              <svg className="w-8 h-8 text-text-muted" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9.172 16.172a4 4 0 015.656 0M9 10h.01M15 10h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
              </svg>
            </div>
            <p className="text-text-secondary mb-4">Workout not found</p>
            <Link to="/" className="text-primary font-semibold hover:underline">
              Go back home
            </Link>
          </div>
        </div>
      </DashboardLayout>
    );
  }

  const isCompleted = !!workout.completed_at;

  return (
    <DashboardLayout>
      <div className="max-w-2xl mx-auto space-y-6">
        {/* Workout Header Card */}
        <div
          className="relative overflow-hidden rounded-2xl p-6 bg-gradient-to-br from-primary to-secondary"
          style={{
            boxShadow: '0 0 40px rgba(6, 182, 212, 0.3), 0 20px 40px rgba(0,0,0,0.3)',
          }}
        >
          <button
            onClick={() => navigate('/')}
            className="text-white/70 hover:text-white mb-3 flex items-center gap-1 text-sm"
          >
            <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 19l-7-7 7-7" />
            </svg>
            Back to Schedule
          </button>
          <h1 className="text-2xl font-bold text-white">{workout.name}</h1>
          <div className="flex flex-wrap gap-3 mt-3">
            <span className="px-3 py-1 bg-white/20 backdrop-blur rounded-lg text-white text-sm capitalize">
              {workout.type}
            </span>
            <span className="px-3 py-1 bg-white/20 backdrop-blur rounded-lg text-white text-sm capitalize">
              {workout.difficulty}
            </span>
            <span className="px-3 py-1 bg-white/20 backdrop-blur rounded-lg text-white text-sm flex items-center gap-1.5">
              <svg className="w-3.5 h-3.5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z" />
              </svg>
              {workout.duration_minutes} min
            </span>
          </div>
          {isCompleted && (
            <div className="mt-4 inline-flex items-center gap-2 px-3 py-1.5 bg-accent/30 backdrop-blur rounded-lg text-white text-sm">
              <svg className="w-4 h-4 text-accent" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2.5} d="M5 13l4 4L19 7" />
              </svg>
              Completed
            </div>
          )}
        </div>

        {/* Action Buttons */}
        {!isCompleted && (
          <div className="flex gap-3">
            <GlassButton
              variant="primary"
              onClick={handleStartWorkout}
              fullWidth
              icon={
                <svg className="w-5 h-5" fill="currentColor" viewBox="0 0 24 24">
                  <path d="M8 5v14l11-7z" />
                </svg>
              }
            >
              Start Workout
            </GlassButton>
            <GlassButton
              variant="secondary"
              onClick={() => navigate('/chat')}
              fullWidth
              icon={
                <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 3v4M3 5h4M6 17v4m-2-2h4m5-16l2.286 6.857L21 12l-5.714 2.143L13 21l-2.286-6.857L5 12l5.714-2.143L13 3z" />
                </svg>
              }
            >
              Modify with AI
            </GlassButton>
          </div>
        )}

        {/* Warmup Section */}
        <GlassCard className="p-6">
          <button
            onClick={() => setWarmupExpanded(!warmupExpanded)}
            className="w-full flex items-center justify-between cursor-pointer"
          >
            <div className="flex items-center gap-3">
              <div className="p-2 bg-orange-500/20 rounded-xl text-orange-400">
                <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M17.657 18.657A8 8 0 016.343 7.343S7 9 9 10c0-2 .5-5 2.986-7C14 5 16.09 5.777 17.656 7.343A7.975 7.975 0 0120 13a7.975 7.975 0 01-2.343 5.657z" />
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9.879 16.121A3 3 0 1012.015 11L11 14H9c0 .768.293 1.536.879 2.121z" />
                </svg>
              </div>
              <div className="text-left">
                <h2 className="text-lg font-semibold text-text">Warm-up</h2>
                <p className="text-xs text-text-secondary">
                  {loadingWarmupStretches
                    ? 'Loading...'
                    : warmup?.exercises_json?.length
                      ? `${warmup.exercises_json.length} exercises • ${warmup.duration_minutes} min`
                      : 'No warmup'}
                </p>
              </div>
            </div>
            <svg
              className={`w-5 h-5 text-text-secondary transition-transform duration-200 ${warmupExpanded ? 'rotate-180' : ''}`}
              fill="none"
              stroke="currentColor"
              viewBox="0 0 24 24"
            >
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 9l-7 7-7-7" />
            </svg>
          </button>

          {warmupExpanded && (
            <div className="mt-5">
              {loadingWarmupStretches ? (
                <div className="flex items-center justify-center py-4">
                  <div className="flex items-center gap-3 text-text-secondary">
                    <div className="w-5 h-5 border-2 border-orange-400 border-t-transparent rounded-full animate-spin" />
                    <span className="text-sm">Loading warmup...</span>
                  </div>
                </div>
              ) : warmup?.exercises_json?.length ? (
                <div className="space-y-2">
                  {warmup.exercises_json.map((exercise, index) => (
                    <div
                      key={index}
                      className="p-3 bg-orange-500/5 rounded-xl border border-orange-500/20"
                    >
                      <div className="flex justify-between items-center">
                        <div className="flex items-center gap-3">
                          <span className="w-6 h-6 bg-orange-500/20 text-orange-400 rounded-lg flex items-center justify-center text-xs font-bold">
                            {index + 1}
                          </span>
                          <span className="font-medium text-text text-sm">{exercise.name}</span>
                        </div>
                        <div className="flex gap-2 text-xs text-text-secondary">
                          {exercise.duration_seconds && <span>{exercise.duration_seconds}s</span>}
                          {exercise.reps && <span>{exercise.reps} reps</span>}
                        </div>
                      </div>
                    </div>
                  ))}
                </div>
              ) : (
                <p className="text-sm text-text-muted text-center py-2">No warmup exercises</p>
              )}
            </div>
          )}
        </GlassCard>

        {/* Exercises */}
        <GlassCard className="p-6">
          <div className="flex items-center gap-3 mb-5">
            <div className="p-2 bg-primary/20 rounded-xl text-primary">
              <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2" />
              </svg>
            </div>
            <div>
              <h2 className="text-lg font-semibold text-text">Exercises</h2>
              <p className="text-xs text-text-secondary">{workout.exercises.length} exercises</p>
            </div>
          </div>

          <div className="space-y-3">
            {workout.exercises.map((exercise, index) => (
              <div
                key={index}
                className="p-4 bg-white/5 rounded-xl border border-white/10 hover:bg-white/[0.08] transition-colors"
              >
                <div className="flex justify-between items-start">
                  <div className="flex-1">
                    <div className="flex items-center gap-3">
                      <span className="w-7 h-7 bg-primary/20 text-primary rounded-lg flex items-center justify-center text-sm font-bold">
                        {index + 1}
                      </span>
                      <h3 className="font-semibold text-text">{exercise.name}</h3>
                    </div>
                    <div className="mt-2 flex flex-wrap gap-2 ml-10">
                      <span className="px-2.5 py-1 bg-white/5 text-text-secondary text-xs rounded-lg border border-white/10">
                        {exercise.sets} sets
                      </span>
                      <span className="px-2.5 py-1 bg-white/5 text-text-secondary text-xs rounded-lg border border-white/10">
                        {exercise.reps} reps
                      </span>
                      {exercise.weight && (
                        <span className="px-2.5 py-1 bg-accent/15 text-accent text-xs rounded-lg border border-accent/30">
                          {exercise.weight} lbs
                        </span>
                      )}
                    </div>
                  </div>
                  <div className="text-xs text-text-muted bg-white/5 px-2.5 py-1 rounded-lg border border-white/10">
                    Rest: {exercise.rest_seconds}s
                  </div>
                </div>
                {exercise.notes && (
                  <p className="mt-3 text-sm text-text-muted ml-10 italic border-l-2 border-white/10 pl-3">
                    {exercise.notes}
                  </p>
                )}
              </div>
            ))}
          </div>
        </GlassCard>

        {/* Stretches Section */}
        <GlassCard className="p-6">
          <button
            onClick={() => setStretchesExpanded(!stretchesExpanded)}
            className="w-full flex items-center justify-between cursor-pointer"
          >
            <div className="flex items-center gap-3">
              <div className="p-2 bg-green-500/20 rounded-xl text-green-400">
                <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4.318 6.318a4.5 4.5 0 000 6.364L12 20.364l7.682-7.682a4.5 4.5 0 00-6.364-6.364L12 7.636l-1.318-1.318a4.5 4.5 0 00-6.364 0z" />
                </svg>
              </div>
              <div className="text-left">
                <h2 className="text-lg font-semibold text-text">Cool-down Stretches</h2>
                <p className="text-xs text-text-secondary">
                  {loadingWarmupStretches
                    ? 'Loading...'
                    : stretches?.exercises_json?.length
                      ? `${stretches.exercises_json.length} stretches • ${stretches.duration_minutes} min`
                      : 'No stretches'}
                </p>
              </div>
            </div>
            <svg
              className={`w-5 h-5 text-text-secondary transition-transform duration-200 ${stretchesExpanded ? 'rotate-180' : ''}`}
              fill="none"
              stroke="currentColor"
              viewBox="0 0 24 24"
            >
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 9l-7 7-7-7" />
            </svg>
          </button>

          {stretchesExpanded && (
            <div className="mt-5">
              {loadingWarmupStretches ? (
                <div className="flex items-center justify-center py-4">
                  <div className="flex items-center gap-3 text-text-secondary">
                    <div className="w-5 h-5 border-2 border-green-400 border-t-transparent rounded-full animate-spin" />
                    <span className="text-sm">Loading stretches...</span>
                  </div>
                </div>
              ) : stretches?.exercises_json?.length ? (
                <div className="space-y-2">
                  {stretches.exercises_json.map((stretch, index) => (
                    <div
                      key={index}
                      className="p-3 bg-green-500/5 rounded-xl border border-green-500/20"
                    >
                      <div className="flex justify-between items-center">
                        <div className="flex items-center gap-3">
                          <span className="w-6 h-6 bg-green-500/20 text-green-400 rounded-lg flex items-center justify-center text-xs font-bold">
                            {index + 1}
                          </span>
                          <span className="font-medium text-text text-sm">{stretch.name}</span>
                        </div>
                        <div className="flex gap-2 text-xs text-text-secondary">
                          {stretch.duration_seconds && <span>{stretch.duration_seconds}s</span>}
                          {stretch.reps && <span>{stretch.reps} reps</span>}
                        </div>
                      </div>
                    </div>
                  ))}
                </div>
              ) : (
                <p className="text-sm text-text-muted text-center py-2">No stretches</p>
              )}
            </div>
          )}
        </GlassCard>

        {/* Notes */}
        {workout.notes && (
          <GlassCard className="p-5">
            <div className="flex items-center gap-2 mb-3">
              <svg className="w-4 h-4 text-text-secondary" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z" />
              </svg>
              <h2 className="font-semibold text-text">Notes</h2>
            </div>
            <p className="text-text-secondary text-sm">{workout.notes}</p>
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
          icon={
            <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" />
            </svg>
          }
        >
          Delete Workout
        </GlassButton>
      </div>
    </DashboardLayout>
  );
}
