import { useEffect, useState, useRef } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { useAppStore } from '../store';
import { getWorkouts, generateWorkout, deleteWorkout, generateWeeklyWorkouts, generateRemainingWorkouts } from '../api/client';
import GenerateWorkoutModal from '../components/GenerateWorkoutModal';
import WorkoutTimeline from '../components/WorkoutTimelineWithDnD';
import { createLogger } from '../utils/logger';

const log = createLogger('home');

export default function Home() {
  const navigate = useNavigate();
  const queryClient = useQueryClient();
  const { user, workouts, setWorkouts } = useAppStore();
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
      if (params.user_id !== user.id) return; // Wrong user

      backgroundGenerationStarted.current = true;
      log.info('Starting background workout generation', params);

      // Clear the pending flag immediately
      localStorage.removeItem('pendingWorkoutGeneration');

      // Start background generation
      setIsBackgroundGenerating(true);
      const estimatedTotal = params.selected_days.length * 4; // Estimate ~4 weeks
      setBackgroundProgress({ generated: 0, total: estimatedTotal });

      // Start polling for new workouts every 3 seconds
      const pollInterval = setInterval(async () => {
        try {
          const freshWorkouts = await getWorkouts(params.user_id);
          setWorkouts(freshWorkouts);
          // Update progress based on actual workout count (subtract 1 for the first workout)
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

          // Final refresh
          queryClient.invalidateQueries({ queryKey: ['workouts'] });
          setBackgroundProgress({ generated: result.total_generated, total: result.total_generated });

          // Hide progress bar after a short delay
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
  }, [user, queryClient]);

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

  // Get today's uncompleted workouts to delete when generating new one
  const todayWorkouts = workouts.filter((w) => {
    const today = new Date().toISOString().split('T')[0];
    return (w.scheduled_date?.startsWith(today) || !w.completed_at) && !w.completed_at;
  });

  const generateMutation = useMutation({
    mutationFn: async (params: {
      fitnessLevel: string;
      goals: string[];
      equipment: string[];
      selectedDays: number[];
    }) => {
      // If multiple days selected, use weekly generation
      if (params.selectedDays.length > 1) {
        // Calculate week start date (Monday)
        const today = new Date();
        const dayOfWeek = today.getDay();
        const mondayOffset = dayOfWeek === 0 ? -6 : 1 - dayOfWeek;
        const monday = new Date(today);
        monday.setDate(today.getDate() + mondayOffset);
        const weekStart = monday.toISOString().split('T')[0];

        // First, delete any existing workouts on the selected days
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

        // Generate weekly workouts
        return generateWeeklyWorkouts({
          user_id: user!.id,
          week_start_date: weekStart,
          selected_days: params.selectedDays,
          duration_minutes: 45,
        });
      } else if (params.selectedDays.length === 1) {
        // Single day: use single workout generation
        // First, delete existing today's uncompleted workouts
        for (const workout of todayWorkouts) {
          await deleteWorkout(workout.id);
        }

        // Then generate new workout with user preferences
        const newWorkout = await generateWorkout({
          user_id: user!.id,
          duration_minutes: 45,
          fitness_level: params.fitnessLevel,
          goals: params.goals,
          equipment: params.equipment,
        });
        return [newWorkout]; // Return as array for consistent handling
      } else {
        throw new Error('Please select at least one day');
      }
    },
    onSuccess: (newWorkouts) => {
      // Get IDs of workouts that were deleted
      const deletedWorkoutIds = new Set<number>();
      if (pendingGenerateData) {
        // Calculate which workouts would have been deleted
        const today = new Date();
        const dayOfWeek = today.getDay();
        const mondayOffset = dayOfWeek === 0 ? -6 : 1 - dayOfWeek;
        const monday = new Date(today);
        monday.setDate(today.getDate() + mondayOffset);

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

      // Remove deleted workouts and add new ones
      const remainingWorkouts = workouts.filter(w => !deletedWorkoutIds.has(w.id));
      setWorkouts([...remainingWorkouts, ...newWorkouts]);

      // Invalidate queries to refresh data
      queryClient.invalidateQueries({ queryKey: ['workouts'] });

      setShowGenerateModal(false);
      setShowReplaceConfirm(false);
      setPendingGenerateData(null);
      setGenerateError(null);

      // Navigate to first new workout
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

    // Calculate which workouts would be replaced
    const today = new Date();
    const dayOfWeek = today.getDay();
    const mondayOffset = dayOfWeek === 0 ? -6 : 1 - dayOfWeek;
    const monday = new Date(today);
    monday.setDate(today.getDate() + mondayOffset);

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

    // Check if there are workouts that would be replaced
    if (workoutsToReplace.length > 0) {
      setPendingGenerateData(data);
      setShowReplaceConfirm(true);
    } else {
      // No existing workouts, generate directly
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
      {/* Header */}
      <header className="bg-primary text-white p-6">
        <div className="max-w-2xl mx-auto">
          <div className="flex justify-between items-center">
            <div>
              <p className="text-primary-dark/70 text-sm">Welcome back</p>
              <h1 className="text-2xl font-bold">Workouts</h1>
            </div>
            <div className="flex gap-2">
              <Link
                to="/chat"
                className="p-3 bg-white/20 rounded-full hover:bg-white/30 transition-colors"
                title="AI Coach"
              >
                <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M8 12h.01M12 12h.01M16 12h.01M21 12c0 4.418-4.03 8-9 8a9.863 9.863 0 01-4.255-.949L3 20l1.395-3.72C3.512 15.042 3 13.574 3 12c0-4.418 4.03-8 9-8s9 3.582 9 8z" />
                </svg>
              </Link>
              <Link
                to="/settings"
                className="p-3 bg-white/20 rounded-full hover:bg-white/30 transition-colors"
                title="Settings"
              >
                <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M10.325 4.317c.426-1.756 2.924-1.756 3.35 0a1.724 1.724 0 002.573 1.066c1.543-.94 3.31.826 2.37 2.37a1.724 1.724 0 001.065 2.572c1.756.426 1.756 2.924 0 3.35a1.724 1.724 0 00-1.066 2.573c.94 1.543-.826 3.31-2.37 2.37a1.724 1.724 0 00-2.572 1.065c-.426 1.756-2.924 1.756-3.35 0a1.724 1.724 0 00-2.573-1.066c-1.543.94-3.31-.826-2.37-2.37a1.724 1.724 0 00-1.065-2.572c-1.756-.426-1.756-2.924 0-3.35a1.724 1.724 0 001.066-2.573c-.94-1.543.826-3.31 2.37-2.37.996.608 2.296.07 2.572-1.065z" />
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" />
                </svg>
              </Link>
            </div>
          </div>
        </div>
      </header>

      <main className="max-w-2xl mx-auto p-4 space-y-6">
        {/* Background Generation Progress */}
        {isBackgroundGenerating && backgroundProgress && (
          <div className="bg-gradient-to-r from-primary/10 to-secondary/10 rounded-xl p-4 border border-primary/20">
            <div className="flex items-center gap-3 mb-2">
              <div className="w-8 h-8 bg-primary/20 rounded-full flex items-center justify-center">
                <svg className="w-4 h-4 text-primary animate-spin" fill="none" viewBox="0 0 24 24">
                  <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4" />
                  <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z" />
                </svg>
              </div>
              <div className="flex-1">
                <p className="text-sm font-medium text-gray-900">
                  {backgroundProgress.generated === backgroundProgress.total
                    ? 'All workouts ready!'
                    : 'Generating your monthly workouts...'}
                </p>
                <p className="text-xs text-gray-500">
                  {backgroundProgress.generated === backgroundProgress.total
                    ? `${backgroundProgress.total} workouts created`
                    : 'This happens in the background - you can browse your schedule'}
                </p>
              </div>
            </div>
            <div className="w-full bg-gray-200 rounded-full h-2 overflow-hidden">
              <div
                className="bg-primary h-2 rounded-full transition-all duration-500 ease-out"
                style={{
                  width: backgroundProgress.generated === 0
                    ? '10%'
                    : `${Math.min(100, (backgroundProgress.generated / backgroundProgress.total) * 100)}%`,
                }}
              />
            </div>
          </div>
        )}

        {/* Quick Stats */}
        <div className="grid grid-cols-3 gap-3">
          <div className="bg-white rounded-xl p-4 text-center border border-gray-100">
            <div className="text-2xl font-bold text-primary">{completedWorkouts.length}</div>
            <div className="text-xs text-gray-500">Completed</div>
          </div>
          <div className="bg-white rounded-xl p-4 text-center border border-gray-100">
            <div className="text-2xl font-bold text-secondary">{user.goals.length}</div>
            <div className="text-xs text-gray-500">Goals</div>
          </div>
          <div className="bg-white rounded-xl p-4 text-center border border-gray-100">
            <div className="text-2xl font-bold text-accent capitalize text-sm">{user.fitness_level}</div>
            <div className="text-xs text-gray-500">Level</div>
          </div>
        </div>

        {/* Workout Timeline */}
        <section>
          <div className="flex justify-between items-center mb-4">
            <h2 className="text-lg font-bold text-gray-900">Your Schedule</h2>
            <button
              onClick={handleOpenGenerateModal}
              disabled={generateMutation.isPending}
              className="flex items-center gap-2 px-4 py-2 bg-primary text-white rounded-lg text-sm font-semibold hover:bg-primary-dark disabled:opacity-50 transition-colors"
            >
              <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 6v6m0 0v6m0-6h6m-6 0H6" />
              </svg>
              {generateMutation.isPending ? 'Creating...' : 'New Workout'}
            </button>
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
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50 p-4">
          <div className="bg-white rounded-2xl p-6 max-w-sm w-full shadow-xl">
            <div className="text-center mb-4">
              <div className="w-12 h-12 bg-amber-100 rounded-full flex items-center justify-center mx-auto mb-3">
                <svg className="w-6 h-6 text-amber-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z" />
                </svg>
              </div>
              <h3 className="text-lg font-bold text-gray-900">Replace Existing Workouts?</h3>
              <p className="text-gray-600 mt-2 text-sm">
                You are generating {pendingGenerateData.selectedDays.length} new workout{pendingGenerateData.selectedDays.length > 1 ? 's' : ''}.
                This will replace any existing workouts on those days.
              </p>
            </div>

            {generateError && (
              <div className="mb-4 p-3 bg-red-50 border border-red-200 rounded-lg">
                <p className="text-red-700 text-sm">{generateError}</p>
              </div>
            )}

            <div className="flex gap-3">
              <button
                onClick={handleCancelReplace}
                disabled={generateMutation.isPending}
                className="flex-1 px-4 py-3 border border-gray-300 text-gray-700 rounded-xl font-semibold hover:bg-gray-50 transition-colors disabled:opacity-50"
              >
                Cancel
              </button>
              <button
                onClick={handleConfirmReplace}
                disabled={generateMutation.isPending}
                className="flex-1 px-4 py-3 bg-primary text-white rounded-xl font-semibold hover:bg-primary-dark transition-colors disabled:opacity-50"
              >
                {generateMutation.isPending ? 'Generating...' : 'Replace'}
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Error Toast */}
      {generateError && !showReplaceConfirm && (
        <div className="fixed bottom-24 left-4 right-4 z-50">
          <div className="bg-red-500 text-white p-4 rounded-xl shadow-lg flex items-center gap-3">
            <svg className="w-5 h-5 flex-shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
            </svg>
            <span className="flex-1 text-sm">{generateError}</span>
            <button
              onClick={() => setGenerateError(null)}
              className="p-1 hover:bg-white/20 rounded"
            >
              <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
              </svg>
            </button>
          </div>
        </div>
      )}
    </div>
  );
}
