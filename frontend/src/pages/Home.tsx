import { useEffect, useState, useRef } from 'react';
import { useNavigate } from 'react-router-dom';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { motion } from 'framer-motion';
import { useAppStore } from '../store';
import { getWorkouts, generateWorkout, deleteWorkout, generateWeeklyWorkouts, generateRemainingWorkouts } from '../api/client';
import GenerateWorkoutModal from '../components/GenerateWorkoutModal';
import WorkoutTimeline from '../components/WorkoutTimelineWithDnD';
import { DashboardLayout } from '../components/layout';
import { GlassCard, GlassButton, ProgressBar } from '../components/ui';
import { createLogger } from '../utils/logger';
import type { Workout } from '../types';
import {
  toolbarVariants,
  toolbarItemVariants,
  fadeInUpVariants,
  cardVariants,
  badgePulseVariants,
} from '../utils/animations';

const log = createLogger('home');

// Calculate current workout streak
function calculateStreak(workouts: Workout[]): number {
  const completedWorkouts = workouts
    .filter(w => w.completed_at)
    .sort((a, b) => new Date(b.completed_at!).getTime() - new Date(a.completed_at!).getTime());

  if (completedWorkouts.length === 0) return 0;

  // Get unique completion dates
  const completionDates = [...new Set(
    completedWorkouts.map(w => new Date(w.completed_at!).toISOString().split('T')[0])
  )].sort((a, b) => new Date(b).getTime() - new Date(a).getTime());

  // Calculate current streak
  let currentStreak = 0;
  const today = new Date();
  today.setHours(0, 0, 0, 0);

  for (let i = 0; i < completionDates.length; i++) {
    const checkDate = new Date(today);
    checkDate.setDate(today.getDate() - i);
    const checkDateStr = checkDate.toISOString().split('T')[0];

    if (completionDates.includes(checkDateStr)) {
      currentStreak++;
    } else if (i === 0) {
      // Today doesn't have a workout, check if yesterday does
      continue;
    } else {
      break;
    }
  }

  return currentStreak;
}

// Stats card component - Premium redesign with animations
function StatCard({ value, label, icon, color, index = 0 }: { value: string | number; label: string; icon: React.ReactNode; color: string; index?: number }) {
  return (
    <motion.div
      className="group relative overflow-hidden rounded-2xl bg-white/5 border border-white/10 p-5"
      variants={cardVariants}
      initial="hidden"
      animate="visible"
      whileHover={{
        scale: 1.03,
        y: -2,
        boxShadow: '0 10px 30px rgba(0, 0, 0, 0.2)',
      }}
      whileTap={{ scale: 0.98 }}
      transition={{
        type: 'spring',
        stiffness: 400,
        damping: 25,
        delay: index * 0.1,
      }}
    >
      {/* Subtle gradient overlay on hover */}
      <motion.div
        className={`absolute inset-0 ${color.replace('text-', 'bg-')}/5`}
        initial={{ opacity: 0 }}
        whileHover={{ opacity: 1 }}
        transition={{ duration: 0.2 }}
      />

      <div className="relative flex items-center gap-4">
        <motion.div
          className={`w-12 h-12 rounded-xl flex items-center justify-center ${color.replace('text-', 'bg-')}/20`}
          whileHover={{ scale: 1.1, rotate: 5 }}
          transition={{ type: 'spring', stiffness: 400, damping: 20 }}
        >
          <span className={color}>{icon}</span>
        </motion.div>
        <div>
          <motion.div
            className="text-2xl font-bold text-text"
            initial={{ opacity: 0, y: 10 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: index * 0.1 + 0.1 }}
          >
            {value}
          </motion.div>
          <motion.div
            className="text-sm text-text-secondary font-medium"
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            transition={{ delay: index * 0.1 + 0.2 }}
          >
            {label}
          </motion.div>
        </div>
      </div>
    </motion.div>
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
      navigate('/login');
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

  // Get today's date for filtering
  const today = new Date().toISOString().split('T')[0];

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
      const deletedWorkoutIds = new Set<string>();
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
  // Get user's name from backend user object first, then onboardingData, then fallback
  const userName = user?.name || onboardingData?.name || 'there';
  const streak = calculateStreak(workouts);

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
    <DashboardLayout>
      <div className="pb-24">
        {/* Premium Header with Animations */}
        <motion.header
          className="relative z-10 border-b border-white/5 bg-surface/50 backdrop-blur-xl"
          variants={toolbarVariants}
          initial="hidden"
          animate="visible"
        >
          <div className="max-w-6xl mx-auto px-6 lg:px-8 py-8">
            <div className="flex flex-col lg:flex-row lg:items-center lg:justify-between gap-6">
              {/* Welcome Section */}
              <motion.div
                className="flex items-center gap-5"
                variants={toolbarItemVariants}
              >
                <motion.div
                  className="relative"
                  whileHover={{ scale: 1.05 }}
                  transition={{ type: 'spring', stiffness: 400, damping: 20 }}
                >
                  <motion.div
                    className="w-16 h-16 rounded-2xl bg-gradient-to-br from-primary/20 to-secondary/20 flex items-center justify-center"
                    initial={{ scale: 0, rotate: -180 }}
                    animate={{ scale: 1, rotate: 0 }}
                    transition={{ type: 'spring', stiffness: 300, damping: 20, delay: 0.1 }}
                  >
                    <span className="text-2xl font-bold text-primary">
                      {userName.charAt(0).toUpperCase()}
                    </span>
                  </motion.div>
                  {streak > 0 && (
                    <motion.div
                      className="absolute -bottom-1 -right-1 w-6 h-6 rounded-full bg-orange flex items-center justify-center border-2 border-background"
                      initial={{ scale: 0 }}
                      animate={{ scale: 1 }}
                      transition={{ type: 'spring', stiffness: 500, damping: 20, delay: 0.3 }}
                      variants={badgePulseVariants}
                      whileHover="pulse"
                    >
                      <svg className="w-3 h-3 text-white" fill="currentColor" viewBox="0 0 24 24">
                        <path d="M13.5.67s.74 2.65.74 4.8c0 2.06-1.35 3.73-3.41 3.73-2.07 0-3.63-1.67-3.63-3.73l.03-.36C5.21 7.51 4 10.62 4 14c0 4.42 3.58 8 8 8s8-3.58 8-8C20 8.61 17.41 3.8 13.5.67z"/>
                      </svg>
                    </motion.div>
                  )}
                </motion.div>
                <motion.div
                  initial={{ opacity: 0, x: -20 }}
                  animate={{ opacity: 1, x: 0 }}
                  transition={{ delay: 0.2 }}
                >
                  <p className="text-text-secondary text-sm font-medium">Welcome back,</p>
                  <h1 className="text-2xl lg:text-3xl font-bold text-text">{userName}</h1>
                  {streak > 0 && (
                    <motion.p
                      className="text-orange text-sm font-medium mt-1"
                      initial={{ opacity: 0 }}
                      animate={{ opacity: 1 }}
                      transition={{ delay: 0.4 }}
                    >
                      {streak} day streak!
                    </motion.p>
                  )}
                </motion.div>
              </motion.div>

              {/* Quick Stats - Desktop with animations */}
              <motion.div
                className="hidden lg:flex items-center gap-4"
                variants={toolbarItemVariants}
              >
                <motion.div
                  className="flex items-center gap-3 px-4 py-3 rounded-2xl bg-white/5 border border-white/10"
                  whileHover={{ scale: 1.05, y: -2 }}
                  transition={{ type: 'spring', stiffness: 400, damping: 20 }}
                >
                  <motion.div
                    className="w-10 h-10 rounded-xl bg-accent/20 flex items-center justify-center"
                    whileHover={{ rotate: 10 }}
                  >
                    <svg className="w-5 h-5 text-accent" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 13l4 4L19 7" />
                    </svg>
                  </motion.div>
                  <div>
                    <div className="text-lg font-bold text-text">{completedWorkouts.length}</div>
                    <div className="text-xs text-text-secondary">Completed</div>
                  </div>
                </motion.div>

                <motion.div
                  className="flex items-center gap-3 px-4 py-3 rounded-2xl bg-white/5 border border-white/10"
                  whileHover={{ scale: 1.05, y: -2 }}
                  transition={{ type: 'spring', stiffness: 400, damping: 20 }}
                >
                  <motion.div
                    className="w-10 h-10 rounded-xl bg-secondary/20 flex items-center justify-center"
                    whileHover={{ rotate: 10 }}
                  >
                    <svg className="w-5 h-5 text-secondary" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M13 10V3L4 14h7v7l9-11h-7z" />
                    </svg>
                  </motion.div>
                  <div>
                    <div className="text-lg font-bold text-text capitalize">{user.fitness_level}</div>
                    <div className="text-xs text-text-secondary">Level</div>
                  </div>
                </motion.div>
              </motion.div>
            </div>
          </div>
        </motion.header>

        <main className="relative z-10 max-w-6xl mx-auto px-6 lg:px-8 py-8 space-y-8">
          {/* Background Generation Progress */}
          {isBackgroundGenerating && backgroundProgress && (
            <GlassCard className="p-5" variant="glow" glowColor="primary">
              <div className="flex items-center gap-4 mb-4">
                <div className="w-12 h-12 bg-primary/20 rounded-xl flex items-center justify-center">
                  <svg className="w-6 h-6 text-primary animate-spin" fill="none" viewBox="0 0 24 24">
                    <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4" />
                    <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z" />
                  </svg>
                </div>
                <div className="flex-1">
                  <p className="font-semibold text-text">
                    {backgroundProgress.generated === backgroundProgress.total
                      ? 'All workouts ready!'
                      : 'Generating your monthly workouts...'}
                  </p>
                  <p className="text-sm text-text-secondary">
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

          {/* Quick Stats - Mobile Only */}
          <motion.section
            className="lg:hidden"
            variants={fadeInUpVariants}
            initial="hidden"
            animate="visible"
            transition={{ delay: 0.2 }}
          >
            <div className="grid grid-cols-3 gap-3">
              <StatCard
                value={completedWorkouts.length}
                label="Completed"
                color="text-accent"
                index={0}
                icon={
                  <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 13l4 4L19 7" />
                  </svg>
                }
              />
              <StatCard
                value={user.goals.length}
                label="Goals"
                color="text-secondary"
                index={1}
                icon={
                  <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M13 10V3L4 14h7v7l9-11h-7z" />
                  </svg>
                }
              />
              <StatCard
                value={user.fitness_level.charAt(0).toUpperCase() + user.fitness_level.slice(1)}
                label="Level"
                color="text-orange"
                index={2}
                icon={
                  <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z" />
                  </svg>
                }
              />
            </div>
          </motion.section>

          {/* Workout Schedule Section */}
          <motion.section
            variants={fadeInUpVariants}
            initial="hidden"
            animate="visible"
            transition={{ delay: 0.3 }}
          >
            {/* Section Header - Apple Fitness Style */}
            <div className="flex items-center justify-between mb-6">
              <motion.div
                initial={{ opacity: 0, x: -20 }}
                animate={{ opacity: 1, x: 0 }}
                transition={{ delay: 0.35 }}
              >
                <h2 className="text-xl lg:text-2xl font-bold text-text">Your Schedule</h2>
                <p className="text-sm text-text-secondary mt-1">Drag workouts to reschedule</p>
              </motion.div>
              <GlassButton
                variant="primary"
                size="md"
                onClick={handleOpenGenerateModal}
                loading={generateMutation.isPending}
                icon={
                  <svg
                    className="w-5 h-5"
                    fill="none"
                    stroke="currentColor"
                    viewBox="0 0 24 24"
                  >
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 6v6m0 0v6m0-6h6m-6 0H6" />
                  </svg>
                }
              >
                New Workout
              </GlassButton>
            </div>

            {/* Timeline Card Container */}
            <motion.div
              className="rounded-2xl bg-white/5 border border-white/10 p-6 lg:p-8"
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: 0.4, duration: 0.3 }}
            >
              <WorkoutTimeline
                workouts={workouts}
                isLoading={isLoading}
                onGenerateWorkout={handleOpenGenerateModal}
                isBackgroundGenerating={isBackgroundGenerating}
              />
            </motion.div>
          </motion.section>
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
          <div className="fixed bottom-24 left-4 right-4 z-50 lg:left-auto lg:right-8 lg:max-w-md">
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
    </DashboardLayout>
  );
}
