import { useEffect, useState, useRef } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { useAppStore } from '../store';
import { getWorkouts, generateWorkout, deleteWorkout, generateWeeklyWorkouts, generateRemainingWorkouts } from '../api/client';
import GenerateWorkoutModal from '../components/GenerateWorkoutModal';
import WorkoutTimeline from '../components/WorkoutTimelineWithDnD';
import { GlassCard, GlassButton, ProgressBar } from '../components/ui';
import { createLogger } from '../utils/logger';
import type { Workout } from '../types';
import { formatDuration } from '../utils/dateUtils';

const log = createLogger('home');

// Workout type gradients and glow colors
const workoutStyles: Record<string, { gradient: string; glow: string }> = {
  strength: { gradient: 'from-indigo-500 to-purple-600', glow: 'rgba(99, 102, 241, 0.4)' },
  cardio: { gradient: 'from-orange-500 to-red-500', glow: 'rgba(249, 115, 22, 0.4)' },
  flexibility: { gradient: 'from-teal-400 to-cyan-500', glow: 'rgba(20, 184, 166, 0.4)' },
  hiit: { gradient: 'from-pink-500 to-rose-500', glow: 'rgba(236, 72, 153, 0.4)' },
  mixed: { gradient: 'from-blue-500 to-indigo-600', glow: 'rgba(59, 130, 246, 0.4)' },
};

// Today's workout card component
function TodayWorkoutCard({ workout }: { workout: Workout }) {
  const style = workoutStyles[workout.type] || workoutStyles.mixed;
  const isCompleted = !!workout.completed_at;

  return (
    <Link to={`/workout/${workout.id}`} className="block">
      <div
        className={`
          relative overflow-hidden rounded-2xl p-6 min-h-[240px]
          bg-gradient-to-br ${style.gradient}
          transition-all duration-300 hover:scale-[1.02]
        `}
        style={{
          boxShadow: `0 0 40px ${style.glow}, 0 20px 40px rgba(0,0,0,0.3)`,
        }}
      >
        {/* Background pattern */}
        <div className="absolute inset-0 opacity-10">
          <svg className="w-full h-full" viewBox="0 0 100 100" preserveAspectRatio="none">
            <defs>
              <pattern id="grid" width="10" height="10" patternUnits="userSpaceOnUse">
                <path d="M 10 0 L 0 0 0 10" fill="none" stroke="white" strokeWidth="0.5" />
              </pattern>
            </defs>
            <rect width="100" height="100" fill="url(#grid)" />
          </svg>
        </div>

        {/* Completed overlay */}
        {isCompleted && (
          <div className="absolute inset-0 bg-black/40 backdrop-blur-sm flex items-center justify-center z-10">
            <div className="text-center">
              <div className="w-16 h-16 rounded-full bg-accent mx-auto flex items-center justify-center mb-2 shadow-[0_0_20px_rgba(20,184,166,0.5)]">
                <svg className="w-10 h-10 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 13l4 4L19 7" />
                </svg>
              </div>
              <p className="text-lg font-semibold text-white">Completed!</p>
            </div>
          </div>
        )}

        {/* Content */}
        <div className="relative z-0 flex flex-col h-full">
          <span className="text-xs font-bold uppercase tracking-wider text-white/70">
            Today's Workout
          </span>

          <div className="flex-1 mt-4">
            <h2 className="text-2xl font-bold text-white mb-1">{workout.name}</h2>
            <p className="text-white/80 capitalize">
              {workout.type} • {workout.difficulty}
            </p>

            <div className="flex items-center gap-4 mt-4 text-white/90">
              <div className="flex items-center gap-2">
                <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z" />
                </svg>
                <span className="font-medium">{formatDuration(workout.duration_minutes)}</span>
              </div>
              <div className="flex items-center gap-2">
                <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2" />
                </svg>
                <span className="font-medium">{workout.exercises.length} exercises</span>
              </div>
            </div>
          </div>

          <div className="mt-4">
            <div className="inline-flex items-center gap-2 px-4 py-2 bg-white/20 backdrop-blur-sm rounded-xl text-white font-medium hover:bg-white/30 transition-colors">
              {isCompleted ? 'View Details' : 'Start Workout'}
              <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 5l7 7-7 7" />
              </svg>
            </div>
          </div>
        </div>
      </div>
    </Link>
  );
}

// Stats card component
function StatCard({ value, label, icon, color }: { value: string | number; label: string; icon: React.ReactNode; color: string }) {
  return (
    <GlassCard className="p-4" hoverable>
      <div className="flex items-center gap-3">
        <div className={`w-10 h-10 rounded-xl flex items-center justify-center ${color}`}>
          {icon}
        </div>
        <div>
          <div className="text-xl font-bold text-text">{value}</div>
          <div className="text-xs text-text-secondary">{label}</div>
        </div>
      </div>
    </GlassCard>
  );
}

export default function Home() {
  const navigate = useNavigate();
  const queryClient = useQueryClient();
  const { user, workouts, setWorkouts, onboardingData } = useAppStore();
  const [showGenerateModal, setShowGenerateModal] = useState(false);
  const [showReplaceConfirm, setShowReplaceConfirm] = useState(false);
  const [pendingGenerateData, setPendingGenerateData] = useState<{
    fitnessLevel: string;
    goals: string[];
    equipment: string[];
    selectedDays: number[];
  } | null>(null);
  const [generateError, setGenerateError] = useState<string | null>(null);

  // Background generation state
  const [isBackgroundGenerating, setIsBackgroundGenerating] = useState(false);
  const [backgroundProgress, setBackgroundProgress] = useState<{
    generated: number;
    total: number;
  } | null>(null);
  const backgroundGenerationStarted = useRef(false);

  useEffect(() => {
    if (!user) {
      navigate('/onboarding');
    }
  }, [user, navigate]);

  // Check for pending background generation on mount
  useEffect(() => {
    if (!user || backgroundGenerationStarted.current) return;

    const pendingGeneration = localStorage.getItem('pendingWorkoutGeneration');
    if (!pendingGeneration) return;

    try {
      const params = JSON.parse(pendingGeneration);
      if (params.user_id !== user.id) return;

      backgroundGenerationStarted.current = true;
      log.info('Starting background workout generation', params);

      localStorage.removeItem('pendingWorkoutGeneration');

      setIsBackgroundGenerating(true);
      const estimatedTotal = params.selected_days.length * 4;
      setBackgroundProgress({ generated: 0, total: estimatedTotal });

      const pollInterval = setInterval(async () => {
        try {
          const freshWorkouts = await getWorkouts(params.user_id);
          setWorkouts(freshWorkouts);
          const generatedCount = Math.max(0, freshWorkouts.length - 1);
          setBackgroundProgress(prev => prev ? { ...prev, generated: generatedCount } : null);
          log.debug(`Polled workouts: ${freshWorkouts.length} total`);
        } catch (e) {
          log.error('Polling failed', e);
        }
      }, 3000);

      generateRemainingWorkouts({
        user_id: params.user_id,
        month_start_date: params.month_start_date,
        selected_days: params.selected_days,
        duration_minutes: params.duration_minutes,
      })
        .then((result) => {
          log.info(`Background generation complete: ${result.total_generated} workouts`);
          clearInterval(pollInterval);

          queryClient.invalidateQueries({ queryKey: ['workouts'] });
          setBackgroundProgress({ generated: result.total_generated, total: result.total_generated });

          setTimeout(() => {
            setIsBackgroundGenerating(false);
            setBackgroundProgress(null);
          }, 2000);
        })
        .catch((error) => {
          log.error('Background generation failed', error);
          clearInterval(pollInterval);
          setIsBackgroundGenerating(false);
          setBackgroundProgress(null);
        });
    } catch (error) {
      log.error('Failed to parse pending generation', error);
      localStorage.removeItem('pendingWorkoutGeneration');
    }
  }, [user, queryClient, setWorkouts]);

  const { data, isLoading } = useQuery({
    queryKey: ['workouts', user?.id],
    queryFn: () => getWorkouts(user!.id),
    enabled: !!user,
  });

  useEffect(() => {
    if (data) {
      setWorkouts(data);
    }
  }, [data, setWorkouts]);

  // Get today's workout
  const today = new Date().toISOString().split('T')[0];
  const todaysWorkout = workouts.find(w => {
    const scheduledDate = w.scheduled_date?.split('T')[0];
    return scheduledDate === today;
  });

  const todayWorkouts = workouts.filter((w) => {
    return (w.scheduled_date?.startsWith(today) || !w.completed_at) && !w.completed_at;
  });

  const generateMutation = useMutation({
    mutationFn: async (params: {
      fitnessLevel: string;
      goals: string[];
      equipment: string[];
      selectedDays: number[];
    }) => {
      if (params.selectedDays.length > 1) {
        const todayDate = new Date();
        const dayOfWeek = todayDate.getDay();
        const mondayOffset = dayOfWeek === 0 ? -6 : 1 - dayOfWeek;
        const monday = new Date(todayDate);
        monday.setDate(todayDate.getDate() + mondayOffset);
        const weekStart = monday.toISOString().split('T')[0];

        const selectedDates = params.selectedDays.map(dayIndex => {
          const date = new Date(monday);
          date.setDate(monday.getDate() + dayIndex);
          return date.toISOString().split('T')[0];
        });

        const workoutsToDelete = workouts.filter(w => {
          if (!w.scheduled_date) return false;
          const workoutDate = w.scheduled_date.split('T')[0];
          return selectedDates.includes(workoutDate) && !w.completed_at;
        });

        for (const workout of workoutsToDelete) {
          await deleteWorkout(workout.id);
        }

        return generateWeeklyWorkouts({
          user_id: user!.id,
          week_start_date: weekStart,
          selected_days: params.selectedDays,
          duration_minutes: 45,
        });
      } else if (params.selectedDays.length === 1) {
        for (const workout of todayWorkouts) {
          await deleteWorkout(workout.id);
        }

        const newWorkout = await generateWorkout({
          user_id: user!.id,
          duration_minutes: 45,
          fitness_level: params.fitnessLevel,
          goals: params.goals,
          equipment: params.equipment,
        });
        return [newWorkout];
      } else {
        throw new Error('Please select at least one day');
      }
    },
    onSuccess: (newWorkouts) => {
      const deletedWorkoutIds = new Set<number>();
      if (pendingGenerateData) {
        const todayDate = new Date();
        const dayOfWeek = todayDate.getDay();
        const mondayOffset = dayOfWeek === 0 ? -6 : 1 - dayOfWeek;
        const monday = new Date(todayDate);
        monday.setDate(todayDate.getDate() + mondayOffset);

        const selectedDates = pendingGenerateData.selectedDays.map(dayIndex => {
          const date = new Date(monday);
          date.setDate(monday.getDate() + dayIndex);
          return date.toISOString().split('T')[0];
        });

        workouts.forEach(w => {
          if (!w.scheduled_date) return;
          const workoutDate = w.scheduled_date.split('T')[0];
          if (selectedDates.includes(workoutDate) && !w.completed_at) {
            deletedWorkoutIds.add(w.id);
          }
        });
      }

      const remainingWorkouts = workouts.filter(w => !deletedWorkoutIds.has(w.id));
      setWorkouts([...remainingWorkouts, ...newWorkouts]);

      queryClient.invalidateQueries({ queryKey: ['workouts'] });

      setShowGenerateModal(false);
      setShowReplaceConfirm(false);
      setPendingGenerateData(null);
      setGenerateError(null);

      if (newWorkouts.length > 0) {
        navigate(`/workout/${newWorkouts[0].id}`);
      }
    },
    onError: (error: Error) => {
      console.error('Failed to generate workout:', error);
      setGenerateError(error.message || 'Failed to generate workout. Please try again.');
    },
  });

  if (!user) return null;

  const completedWorkouts = workouts.filter((w) => w.completed_at);
  const userName = onboardingData?.name || 'there';

  const handleOpenGenerateModal = () => {
    setGenerateError(null);
    setShowGenerateModal(true);
  };

  const handleGenerate = (data: {
    fitnessLevel: string;
    goals: string[];
    equipment: string[];
    selectedDays: number[];
  }) => {
    setGenerateError(null);

    const todayDate = new Date();
    const dayOfWeek = todayDate.getDay();
    const mondayOffset = dayOfWeek === 0 ? -6 : 1 - dayOfWeek;
    const monday = new Date(todayDate);
    monday.setDate(todayDate.getDate() + mondayOffset);

    const selectedDates = data.selectedDays.map(dayIndex => {
      const date = new Date(monday);
      date.setDate(monday.getDate() + dayIndex);
      return date.toISOString().split('T')[0];
    });

    const workoutsToReplace = workouts.filter(w => {
      if (!w.scheduled_date) return false;
      const workoutDate = w.scheduled_date.split('T')[0];
      return selectedDates.includes(workoutDate) && !w.completed_at;
    });

    if (workoutsToReplace.length > 0) {
      setPendingGenerateData(data);
      setShowReplaceConfirm(true);
    } else {
      generateMutation.mutate(data);
    }
  };

  const handleConfirmReplace = () => {
    if (pendingGenerateData) {
      generateMutation.mutate(pendingGenerateData);
    }
  };

  const handleCancelReplace = () => {
    setShowReplaceConfirm(false);
    setPendingGenerateData(null);
  };

  return (
    <div className="min-h-screen bg-background pb-24">
      {/* Background decorations */}
      <div className="fixed inset-0 overflow-hidden pointer-events-none">
        <div className="absolute top-0 right-0 w-[500px] h-[500px] bg-primary/5 rounded-full blur-3xl" />
        <div className="absolute bottom-1/4 left-0 w-[400px] h-[400px] bg-secondary/5 rounded-full blur-3xl" />
      </div>

      {/* Header */}
      <header className="relative z-10 glass-heavy safe-area-top">
        <div className="max-w-2xl mx-auto px-4 py-6">
          <div className="flex justify-between items-center">
            <div>
              <p className="text-text-secondary text-sm">Welcome back,</p>
              <h1 className="text-2xl font-bold text-text">{userName}</h1>
            </div>
            <div className="flex gap-2">
              <Link
                to="/metrics"
                className="p-3 bg-white/10 backdrop-blur-sm rounded-xl border border-white/10 hover:bg-white/15 transition-colors"
                title="Metrics"
              >
                <svg className="w-6 h-6 text-accent" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z" />
                </svg>
              </Link>
              <Link
                to="/chat"
                className="p-3 bg-white/10 backdrop-blur-sm rounded-xl border border-white/10 hover:bg-white/15 transition-colors"
                title="AI Coach"
              >
                <svg className="w-6 h-6 text-primary" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M8 12h.01M12 12h.01M16 12h.01M21 12c0 4.418-4.03 8-9 8a9.863 9.863 0 01-4.255-.949L3 20l1.395-3.72C3.512 15.042 3 13.574 3 12c0-4.418 4.03-8 9-8s9 3.582 9 8z" />
                </svg>
              </Link>
              <Link
                to="/profile"
                className="p-3 bg-white/10 backdrop-blur-sm rounded-xl border border-white/10 hover:bg-white/15 transition-colors"
                title="Profile"
              >
                <svg className="w-6 h-6 text-secondary" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z" />
                </svg>
              </Link>
              <Link
                to="/settings"
                className="p-3 bg-white/10 backdrop-blur-sm rounded-xl border border-white/10 hover:bg-white/15 transition-colors"
                title="Settings"
              >
                <svg className="w-6 h-6 text-text-secondary" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M10.325 4.317c.426-1.756 2.924-1.756 3.35 0a1.724 1.724 0 002.573 1.066c1.543-.94 3.31.826 2.37 2.37a1.724 1.724 0 001.065 2.572c1.756.426 1.756 2.924 0 3.35a1.724 1.724 0 00-1.066 2.573c.94 1.543-.826 3.31-2.37 2.37a1.724 1.724 0 00-2.572 1.065c-.426 1.756-2.924 1.756-3.35 0a1.724 1.724 0 00-2.573-1.066c-1.543.94-3.31-.826-2.37-2.37a1.724 1.724 0 00-1.065-2.572c-1.756-.426-1.756-2.924 0-3.35a1.724 1.724 0 001.066-2.573c-.94-1.543.826-3.31 2.37-2.37.996.608 2.296.07 2.572-1.065z" />
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" />
                </svg>
              </Link>
            </div>
          </div>
        </div>
      </header>

      <main className="relative z-10 max-w-2xl mx-auto px-4 py-6 space-y-6">
        {/* Background Generation Progress */}
        {isBackgroundGenerating && backgroundProgress && (
          <GlassCard className="p-4" variant="glow" glowColor="primary">
            <div className="flex items-center gap-3 mb-3">
              <div className="w-10 h-10 bg-primary/20 rounded-xl flex items-center justify-center">
                <svg className="w-5 h-5 text-primary animate-spin" fill="none" viewBox="0 0 24 24">
                  <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4" />
                  <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z" />
                </svg>
              </div>
              <div className="flex-1">
                <p className="text-sm font-medium text-text">
                  {backgroundProgress.generated === backgroundProgress.total
                    ? 'All workouts ready!'
                    : 'Generating your monthly workouts...'}
                </p>
                <p className="text-xs text-text-secondary">
                  {backgroundProgress.generated === backgroundProgress.total
                    ? `${backgroundProgress.total} workouts created`
                    : 'This happens in the background - you can browse your schedule'}
                </p>
              </div>
            </div>
            <ProgressBar
              current={backgroundProgress.generated || 1}
              total={backgroundProgress.total}
              variant="glow"
            />
          </GlassCard>
        )}

        {/* Today's Workout */}
        {todaysWorkout && (
          <section className="fade-in-up">
            <TodayWorkoutCard workout={todaysWorkout} />
          </section>
        )}

        {/* No workout for today */}
        {!todaysWorkout && !isLoading && (
          <GlassCard className="p-6 text-center" variant="default">
            <div className="w-16 h-16 bg-white/5 rounded-2xl flex items-center justify-center mx-auto mb-4">
              <svg className="w-8 h-8 text-text-muted" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z" />
              </svg>
            </div>
            <h3 className="text-lg font-semibold text-text mb-2">No Workout Today</h3>
            <p className="text-text-secondary mb-4">Take a rest day or generate a new workout</p>
            <GlassButton onClick={handleOpenGenerateModal} size="sm">
              Generate Workout
            </GlassButton>
          </GlassCard>
        )}

        {/* Quick Stats */}
        <section className="fade-in-up stagger-1">
          <div className="grid grid-cols-3 gap-3">
            <StatCard
              value={completedWorkouts.length}
              label="Completed"
              color="bg-accent/20 text-accent"
              icon={
                <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 13l4 4L19 7" />
                </svg>
              }
            />
            <StatCard
              value={user.goals.length}
              label="Goals"
              color="bg-secondary/20 text-secondary"
              icon={
                <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M13 10V3L4 14h7v7l9-11h-7z" />
                </svg>
              }
            />
            <StatCard
              value={user.fitness_level.charAt(0).toUpperCase() + user.fitness_level.slice(1)}
              label="Level"
              color="bg-orange/20 text-orange"
              icon={
                <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z" />
                </svg>
              }
            />
          </div>
        </section>

        {/* Workout Timeline */}
        <section className="fade-in-up stagger-2">
          <div className="flex justify-between items-center mb-4">
            <h2 className="text-lg font-bold text-text">Your Schedule</h2>
            <GlassButton
              variant="primary"
              size="sm"
              onClick={handleOpenGenerateModal}
              loading={generateMutation.isPending}
              icon={
                <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 6v6m0 0v6m0-6h6m-6 0H6" />
                </svg>
              }
            >
              New Workout
            </GlassButton>
          </div>

          <WorkoutTimeline
            workouts={workouts}
            isLoading={isLoading}
            onGenerateWorkout={handleOpenGenerateModal}
            isBackgroundGenerating={isBackgroundGenerating}
          />
        </section>
      </main>

      {/* Generate Workout Modal */}
      <GenerateWorkoutModal
        isOpen={showGenerateModal}
        onClose={() => setShowGenerateModal(false)}
        onGenerate={handleGenerate}
        isGenerating={generateMutation.isPending}
        initialData={{
          fitnessLevel: user.fitness_level,
          goals: user.goals,
          equipment: user.equipment,
        }}
      />

      {/* Replace Workout Confirmation Dialog */}
      {showReplaceConfirm && pendingGenerateData && (
        <div className="fixed inset-0 bg-black/70 backdrop-blur-sm flex items-center justify-center z-50 p-4">
          <GlassCard className="max-w-sm w-full p-6" variant="elevated">
            <div className="text-center mb-4">
              <div className="w-12 h-12 bg-orange/20 rounded-xl flex items-center justify-center mx-auto mb-3">
                <svg className="w-6 h-6 text-orange" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z" />
                </svg>
              </div>
              <h3 className="text-lg font-bold text-text">Replace Existing Workouts?</h3>
              <p className="text-text-secondary mt-2 text-sm">
                You are generating {pendingGenerateData.selectedDays.length} new workout{pendingGenerateData.selectedDays.length > 1 ? 's' : ''}.
                This will replace any existing workouts on those days.
              </p>
            </div>

            {generateError && (
              <div className="mb-4 p-3 bg-coral/10 border border-coral/30 rounded-xl">
                <p className="text-coral text-sm">{generateError}</p>
              </div>
            )}

            <div className="flex gap-3">
              <GlassButton
                variant="secondary"
                onClick={handleCancelReplace}
                disabled={generateMutation.isPending}
                fullWidth
              >
                Cancel
              </GlassButton>
              <GlassButton
                onClick={handleConfirmReplace}
                loading={generateMutation.isPending}
                fullWidth
              >
                Replace
              </GlassButton>
            </div>
          </GlassCard>
        </div>
      )}

      {/* Error Toast */}
      {generateError && !showReplaceConfirm && (
        <div className="fixed bottom-24 left-4 right-4 z-50">
          <GlassCard className="p-4 border-coral/30" variant="default">
            <div className="flex items-center gap-3">
              <svg className="w-5 h-5 text-coral flex-shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
              </svg>
              <span className="flex-1 text-sm text-text">{generateError}</span>
              <button
                onClick={() => setGenerateError(null)}
                className="p-1 hover:bg-white/10 rounded transition-colors"
              >
                <svg className="w-4 h-4 text-text-secondary" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
                </svg>
              </button>
            </div>
          </GlassCard>
        </div>
      )}
    </div>
  );
}
