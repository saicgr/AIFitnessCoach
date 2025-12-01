import { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { useQuery } from '@tanstack/react-query';
import { useAppStore } from '../store';
import { getWorkouts, calculateHealthMetrics, getActiveInjuries, getStrengthRecords, getWeeklyVolumes } from '../api/client';
import { createLogger } from '../utils/logger';
import type { HealthMetrics, ActiveInjury, Workout } from '../types';
import { GlassCard, GlassButton, ProgressBar } from '../components/ui';
import { DashboardLayout } from '../components/layout';

const log = createLogger('metrics');

// Icon components
const Icons = {
  Back: () => (
    <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 19l-7-7 7-7" />
    </svg>
  ),
  Scale: () => (
    <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M3 6l3 1m0 0l-3 9a5.002 5.002 0 006.001 0M6 7l3 9M6 7l6-2m6 2l3-1m-3 1l-3 9a5.002 5.002 0 006.001 0M18 7l3 9m-3-9l-6-2m0-2v2m0 16V5m0 16H9m3 0h3" />
    </svg>
  ),
  Heart: () => (
    <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4.318 6.318a4.5 4.5 0 000 6.364L12 20.364l7.682-7.682a4.5 4.5 0 00-6.364-6.364L12 7.636l-1.318-1.318a4.5 4.5 0 00-6.364 0z" />
    </svg>
  ),
  Fire: () => (
    <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M17.657 18.657A8 8 0 016.343 7.343S7 9 9 10c0-2 .5-5 2.986-7C14 5 16.09 5.777 17.656 7.343A7.975 7.975 0 0120 13a7.975 7.975 0 01-2.343 5.657z" />
    </svg>
  ),
  Trophy: () => (
    <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 3v4M3 5h4M6 17v4m-2-2h4m5-16l2.286 6.857L21 12l-5.714 2.143L13 21l-2.286-6.857L5 12l5.714-2.143L13 3z" />
    </svg>
  ),
  Dumbbell: () => (
    <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z" />
    </svg>
  ),
  TrendUp: () => (
    <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M13 7h8m0 0v8m0-8l-8 8-4-4-6 6" />
    </svg>
  ),
  TrendDown: () => (
    <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M13 17h8m0 0V9m0 8l-8-8-4 4-6-6" />
    </svg>
  ),
  Bandage: () => (
    <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M18.364 5.636l-3.536 3.536m0 5.656l3.536 3.536M9.172 9.172L5.636 5.636m3.536 9.192l-3.536 3.536M21 12a9 9 0 11-18 0 9 9 0 0118 0zm-5 0a4 4 0 11-8 0 4 4 0 018 0z" />
    </svg>
  ),
};

// Quick Stat Card
function StatCard({
  icon,
  value,
  label,
  sublabel,
  color,
}: {
  icon: React.ReactNode;
  value: string | number;
  label: string;
  sublabel?: string;
  color: 'primary' | 'secondary' | 'accent' | 'orange';
}) {
  const colorClasses = {
    primary: 'bg-primary/20 text-primary border-primary/30',
    secondary: 'bg-secondary/20 text-secondary border-secondary/30',
    accent: 'bg-accent/20 text-accent border-accent/30',
    orange: 'bg-orange/20 text-orange border-orange/30',
  };

  return (
    <GlassCard className="p-4" hoverable>
      <div className="flex items-center gap-3">
        <div className={`w-10 h-10 rounded-xl flex items-center justify-center ${colorClasses[color]}`}>
          {icon}
        </div>
        <div className="flex-1 min-w-0">
          <div className="text-xl font-bold text-text truncate">{value}</div>
          <div className="text-xs text-text-secondary">{label}</div>
          {sublabel && <div className="text-xs text-text-muted">{sublabel}</div>}
        </div>
      </div>
    </GlassCard>
  );
}

// Section Header
function SectionHeader({ title, subtitle }: { title: string; subtitle?: string }) {
  return (
    <div className="mb-4">
      <h2 className="text-lg font-bold text-text">{title}</h2>
      {subtitle && <p className="text-xs text-text-secondary">{subtitle}</p>}
    </div>
  );
}

// Volume Bar Component
function VolumeBar({
  label,
  value,
  maxValue,
  target,
}: {
  label: string;
  value: number;
  maxValue: number;
  target?: number;
}) {
  const percent = Math.min((value / maxValue) * 100, 100);
  const isAtTarget = target ? value >= target : true;

  return (
    <div className="mb-3">
      <div className="flex justify-between items-center mb-1">
        <span className="text-sm text-text">{label}</span>
        <span className="text-sm text-text-secondary">
          {value} sets
          {target && <span className="text-text-muted"> / {target}</span>}
        </span>
      </div>
      <div className="h-2.5 bg-white/5 rounded-full overflow-hidden">
        <div
          className={`h-full rounded-full transition-all duration-500 ${
            isAtTarget ? 'bg-gradient-to-r from-accent to-primary' : 'bg-gradient-to-r from-orange to-coral'
          }`}
          style={{ width: `${percent}%` }}
        />
      </div>
    </div>
  );
}

export default function Metrics() {
  const navigate = useNavigate();
  const { user, onboardingData, workouts, setWorkouts } = useAppStore();
  const [healthMetrics, setHealthMetrics] = useState<HealthMetrics | null>(null);
  const [metricsLoading, setMetricsLoading] = useState(false);
  const [activeInjuries, setActiveInjuries] = useState<ActiveInjury[]>([]);

  // Fetch workouts
  const { data: workoutsData } = useQuery({
    queryKey: ['workouts', user?.id],
    queryFn: () => getWorkouts(user!.id),
    enabled: !!user,
  });

  // Fetch strength records (PRs)
  const { data: strengthRecords } = useQuery({
    queryKey: ['strength-records', user?.id],
    queryFn: () => getStrengthRecords(user!.id.toString(), undefined, true),
    enabled: !!user,
  });

  // Fetch weekly volumes from backend
  const currentWeek = Math.ceil((new Date().getDate()) / 7);
  const currentYear = new Date().getFullYear();
  const { data: weeklyVolumes } = useQuery({
    queryKey: ['weekly-volumes', user?.id, currentWeek, currentYear],
    queryFn: () => getWeeklyVolumes(user!.id.toString(), currentWeek, currentYear),
    enabled: !!user,
  });

  useEffect(() => {
    if (workoutsData) {
      setWorkouts(workoutsData);
    }
  }, [workoutsData, setWorkouts]);

  // Calculate health metrics
  useEffect(() => {
    const fetchMetrics = async () => {
      if (!user || !onboardingData.weightKg || !onboardingData.heightCm || !onboardingData.age) return;

      const gender = onboardingData.gender;
      if (gender !== 'male' && gender !== 'female') return;

      setMetricsLoading(true);
      try {
        const metrics = await calculateHealthMetrics({
          userId: user.id,
          weightKg: onboardingData.weightKg,
          heightCm: onboardingData.heightCm,
          age: onboardingData.age,
          gender: gender,
          activityLevel: onboardingData.activityLevel,
          targetWeightKg: onboardingData.targetWeightKg,
          waistCm: onboardingData.waistCircumferenceCm,
          hipCm: onboardingData.hipCircumferenceCm,
          neckCm: onboardingData.neckCircumferenceCm,
          bodyFatPercent: onboardingData.bodyFatPercent,
        });
        setHealthMetrics(metrics);
        log.info('Health metrics calculated', metrics);
      } catch (error) {
        log.error('Failed to calculate health metrics', error);
      } finally {
        setMetricsLoading(false);
      }
    };

    fetchMetrics();
  }, [user, onboardingData]);

  // Fetch injuries
  useEffect(() => {
    const fetchInjuries = async () => {
      if (!user) return;
      try {
        const injuries = await getActiveInjuries(user.id);
        setActiveInjuries(injuries);
      } catch (error) {
        log.error('Failed to fetch injuries', error);
      }
    };
    fetchInjuries();
  }, [user]);

  if (!user) {
    navigate('/login');
    return null;
  }

  // Calculate workout stats
  const completedWorkouts = workouts.filter(w => w.completed_at);
  const totalWorkouts = workouts.length;
  const completionRate = totalWorkouts > 0 ? Math.round((completedWorkouts.length / totalWorkouts) * 100) : 0;

  // Calculate streak
  const calculateStreak = (workouts: Workout[]) => {
    const completedDates = new Set(
      workouts
        .filter(w => w.completed_at)
        .map(w => w.completed_at!.split('T')[0])
    );

    let streak = 0;
    const today = new Date();

    for (let i = 0; i < 30; i++) {
      const date = new Date(today);
      date.setDate(date.getDate() - i);
      const dateStr = date.toISOString().split('T')[0];

      if (completedDates.has(dateStr)) {
        streak++;
      } else if (i > 0) {
        break;
      }
    }

    return streak;
  };

  const streak = calculateStreak(workouts);

  // Calculate total volume (estimated from completed workouts)
  const calculateTotalVolume = () => {
    let totalSets = 0;
    let totalReps = 0;

    completedWorkouts.forEach(workout => {
      workout.exercises.forEach(ex => {
        totalSets += ex.sets;
        totalReps += ex.sets * ex.reps;
      });
    });

    return { totalSets, totalReps };
  };

  const { totalSets, totalReps } = calculateTotalVolume();

  // Group workouts by muscle
  const muscleVolume: Record<string, number> = {};
  completedWorkouts.forEach(workout => {
    workout.exercises.forEach(ex => {
      const muscle = ex.muscle_group || 'Other';
      muscleVolume[muscle] = (muscleVolume[muscle] || 0) + ex.sets;
    });
  });

  const maxMuscleVolume = Math.max(...Object.values(muscleVolume), 15);

  return (
    <DashboardLayout>
      <div className="space-y-6">
        {/* Quick Stats Grid */}
        <section>
          <div className="grid grid-cols-2 gap-3">
            <StatCard
              icon={<Icons.Trophy />}
              value={completedWorkouts.length}
              label="Workouts Completed"
              sublabel={`${completionRate}% completion`}
              color="accent"
            />
            <StatCard
              icon={<Icons.Fire />}
              value={`${streak}d`}
              label="Current Streak"
              color="orange"
            />
            <StatCard
              icon={<Icons.Scale />}
              value={healthMetrics ? healthMetrics.bmi.toFixed(1) : onboardingData.weightKg}
              label={healthMetrics ? 'BMI' : 'Weight (kg)'}
              sublabel={healthMetrics?.bmiCategory}
              color="primary"
            />
            <StatCard
              icon={<Icons.Heart />}
              value={healthMetrics ? Math.round(healthMetrics.tdee).toLocaleString() : '-'}
              label="Daily Calories"
              sublabel="TDEE"
              color="secondary"
            />
          </div>
        </section>

        {/* Body Composition Section */}
        {metricsLoading ? (
          <GlassCard className="p-6">
            <div className="flex flex-col items-center justify-center py-8">
              <div className="w-10 h-10 border-3 border-primary border-t-transparent rounded-full animate-spin mb-3" />
              <p className="text-text-secondary text-sm">Calculating metrics...</p>
            </div>
          </GlassCard>
        ) : healthMetrics ? (
          <GlassCard className="p-6">
            <SectionHeader title="Body Composition" subtitle="Based on your measurements" />

            <div className="space-y-4">
              {/* Weight Progress */}
              <div className="bg-white/5 rounded-xl p-4 border border-white/10">
                <div className="flex justify-between items-center mb-2">
                  <span className="text-text-secondary text-sm">Current Weight</span>
                  <span className="text-xl font-bold text-text">{onboardingData.weightKg} kg</span>
                </div>
                {onboardingData.targetWeightKg && (
                  <>
                    <div className="flex justify-between items-center mb-2">
                      <span className="text-text-muted text-xs">Target</span>
                      <span className="text-text-secondary">{onboardingData.targetWeightKg} kg</span>
                    </div>
                    <ProgressBar
                      current={Math.abs(onboardingData.weightKg - onboardingData.targetWeightKg)}
                      total={Math.abs((onboardingData.targetWeightKg || onboardingData.weightKg) - onboardingData.weightKg) + 10}
                      variant="glow"
                    />
                    <p className="text-xs text-text-muted mt-2">
                      {onboardingData.weightKg > onboardingData.targetWeightKg
                        ? `${(onboardingData.weightKg - onboardingData.targetWeightKg).toFixed(1)} kg to lose`
                        : onboardingData.weightKg < onboardingData.targetWeightKg
                        ? `${(onboardingData.targetWeightKg - onboardingData.weightKg).toFixed(1)} kg to gain`
                        : 'At target weight!'}
                    </p>
                  </>
                )}
              </div>

              {/* BMI Details */}
              <div className="grid grid-cols-2 gap-3">
                <div className="bg-white/5 rounded-xl p-4 border border-white/10">
                  <p className="text-xs text-text-secondary mb-1">BMI</p>
                  <p className="text-2xl font-bold text-text">{healthMetrics.bmi.toFixed(1)}</p>
                  <span className={`text-xs px-2 py-0.5 rounded-full ${
                    healthMetrics.bmiCategory === 'normal'
                      ? 'bg-accent/20 text-accent'
                      : 'bg-orange/20 text-orange'
                  }`}>
                    {healthMetrics.bmiCategory}
                  </span>
                </div>
                <div className="bg-white/5 rounded-xl p-4 border border-white/10">
                  <p className="text-xs text-text-secondary mb-1">Ideal Weight</p>
                  <p className="text-2xl font-bold text-text">
                    {Math.round(healthMetrics.idealBodyWeightMiller)}-{Math.round(healthMetrics.idealBodyWeightDevine)}
                  </p>
                  <span className="text-xs text-text-muted">kg range</span>
                </div>
              </div>

              {/* Metabolic Rates */}
              <div className="grid grid-cols-2 gap-3">
                <div className="bg-primary/10 rounded-xl p-4 border border-primary/20">
                  <p className="text-xs text-primary mb-1">BMR</p>
                  <p className="text-xl font-bold text-text">{Math.round(healthMetrics.bmrMifflin)}</p>
                  <span className="text-xs text-text-muted">kcal/day at rest</span>
                </div>
                <div className="bg-secondary/10 rounded-xl p-4 border border-secondary/20">
                  <p className="text-xs text-secondary mb-1">TDEE</p>
                  <p className="text-xl font-bold text-text">{Math.round(healthMetrics.tdee)}</p>
                  <span className="text-xs text-text-muted">kcal/day total</span>
                </div>
              </div>

              {/* Advanced Metrics */}
              {(healthMetrics.bodyFatNavy || healthMetrics.ffmi) && (
                <div className="grid grid-cols-2 gap-3">
                  {healthMetrics.bodyFatNavy && (
                    <div className="bg-orange/10 rounded-xl p-4 border border-orange/20">
                      <p className="text-xs text-orange mb-1">Body Fat</p>
                      <p className="text-xl font-bold text-text">{healthMetrics.bodyFatNavy.toFixed(1)}%</p>
                      <span className="text-xs text-text-muted">Navy method</span>
                    </div>
                  )}
                  {healthMetrics.leanBodyMass && (
                    <div className="bg-accent/10 rounded-xl p-4 border border-accent/20">
                      <p className="text-xs text-accent mb-1">Lean Mass</p>
                      <p className="text-xl font-bold text-text">{healthMetrics.leanBodyMass.toFixed(1)}</p>
                      <span className="text-xs text-text-muted">kg</span>
                    </div>
                  )}
                </div>
              )}
            </div>
          </GlassCard>
        ) : (
          <GlassCard className="p-6">
            <div className="text-center py-4">
              <p className="text-text-secondary mb-2">Complete your profile to see body metrics</p>
              <GlassButton variant="secondary" size="sm" onClick={() => navigate('/profile')}>
                Update Profile
              </GlassButton>
            </div>
          </GlassCard>
        )}

        {/* Workout Performance Section */}
        <GlassCard className="p-6">
          <SectionHeader title="Workout Performance" subtitle="This month's progress" />

          <div className="space-y-4">
            {/* Completion Stats */}
            <div className="grid grid-cols-3 gap-3">
              <div className="bg-white/5 rounded-xl p-3 text-center border border-white/10">
                <p className="text-2xl font-bold text-text">{completedWorkouts.length}</p>
                <p className="text-xs text-text-muted">Completed</p>
              </div>
              <div className="bg-white/5 rounded-xl p-3 text-center border border-white/10">
                <p className="text-2xl font-bold text-text">{totalSets}</p>
                <p className="text-xs text-text-muted">Total Sets</p>
              </div>
              <div className="bg-white/5 rounded-xl p-3 text-center border border-white/10">
                <p className="text-2xl font-bold text-text">{totalReps}</p>
                <p className="text-xs text-text-muted">Total Reps</p>
              </div>
            </div>

            {/* Completion Rate */}
            <div>
              <div className="flex justify-between items-center mb-2">
                <span className="text-sm text-text">Completion Rate</span>
                <span className="text-sm font-semibold text-accent">{completionRate}%</span>
              </div>
              <ProgressBar current={completionRate} total={100} variant="glow" />
            </div>
          </div>
        </GlassCard>

        {/* Personal Records Section */}
        <GlassCard className="p-6">
          <div className="flex items-center gap-3 mb-4">
            <div className="p-2 bg-amber-500/20 rounded-xl text-amber-400">
              <Icons.Trophy />
            </div>
            <div>
              <h2 className="text-lg font-semibold text-text">Personal Records</h2>
              <p className="text-xs text-text-secondary">Your all-time bests</p>
            </div>
          </div>

          {strengthRecords && strengthRecords.length > 0 ? (
            <div className="space-y-3">
              {strengthRecords.slice(0, 5).map((record) => (
                <div
                  key={record.id}
                  className="bg-gradient-to-r from-amber-500/10 to-orange-500/10 rounded-xl p-4 border border-amber-500/20"
                >
                  <div className="flex justify-between items-start">
                    <div>
                      <p className="font-medium text-text">{record.exercise_name}</p>
                      <div className="flex items-center gap-2 mt-1">
                        <span className="text-xl font-bold text-amber-400">
                          {record.weight_kg.toFixed(1)} kg
                        </span>
                        <span className="text-text-secondary">×</span>
                        <span className="text-lg font-semibold text-text">
                          {record.reps} reps
                        </span>
                      </div>
                    </div>
                    <div className="text-right">
                      <p className="text-xs text-text-muted">Est. 1RM</p>
                      <p className="text-lg font-bold text-primary">
                        {record.estimated_1rm.toFixed(1)} kg
                      </p>
                    </div>
                  </div>
                  <p className="text-xs text-text-muted mt-2">
                    Achieved {new Date(record.achieved_at).toLocaleDateString()}
                  </p>
                </div>
              ))}
            </div>
          ) : (
            <div className="text-center py-6">
              <div className="text-4xl mb-3">🏆</div>
              <p className="text-text-secondary mb-2">No personal records yet</p>
              <p className="text-xs text-text-muted">
                Complete workouts with the active workout tracker to log your PRs
              </p>
            </div>
          )}
        </GlassCard>

        {/* Volume by Muscle Group - Use backend data if available */}
        {(weeklyVolumes && weeklyVolumes.length > 0) || Object.keys(muscleVolume).length > 0 ? (
          <GlassCard className="p-6">
            <SectionHeader title="Volume by Muscle" subtitle="Sets completed this week" />

            <div className="space-y-1">
              {weeklyVolumes && weeklyVolumes.length > 0 ? (
                // Use backend weekly volumes
                weeklyVolumes
                  .sort((a, b) => b.total_sets - a.total_sets)
                  .slice(0, 6)
                  .map((vol) => (
                    <VolumeBar
                      key={vol.muscle_group}
                      label={vol.muscle_group}
                      value={vol.total_sets}
                      maxValue={Math.max(...weeklyVolumes.map(v => v.total_sets), 15)}
                      target={vol.target_sets || 10}
                    />
                  ))
              ) : (
                // Fall back to calculated from workouts
                Object.entries(muscleVolume)
                  .sort((a, b) => b[1] - a[1])
                  .slice(0, 6)
                  .map(([muscle, sets]) => (
                    <VolumeBar
                      key={muscle}
                      label={muscle}
                      value={sets}
                      maxValue={maxMuscleVolume}
                      target={10}
                    />
                  ))
              )}
            </div>
          </GlassCard>
        ) : (
          <GlassCard className="p-6">
            <SectionHeader title="Volume by Muscle" subtitle="Sets completed this week" />
            <p className="text-center text-text-muted py-4">
              Complete workouts to see volume breakdown
            </p>
          </GlassCard>
        )}

        {/* Active Injuries / Report Injury */}
        <GlassCard className="p-6 border-orange/30">
          <div className="flex items-center justify-between mb-4">
            <div className="flex items-center gap-3">
              <div className="p-2 bg-orange/20 rounded-xl text-orange">
                <Icons.Bandage />
              </div>
              <div>
                <h2 className="text-lg font-semibold text-text">Recovery Status</h2>
                <p className="text-xs text-text-secondary">
                  {activeInjuries.length > 0
                    ? `${activeInjuries.length} active injuries`
                    : 'No active injuries'}
                </p>
              </div>
            </div>
            <button
              onClick={() => navigate('/chat', { state: { prefillMessage: 'I want to report a new injury' } })}
              className="px-3 py-1.5 bg-orange/20 hover:bg-orange/30 text-orange rounded-lg text-sm font-medium transition-colors flex items-center gap-1.5"
            >
              <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 4v16m8-8H4" />
              </svg>
              Report Injury
            </button>
          </div>

          {activeInjuries.length > 0 ? (
            <div className="space-y-3">
              {activeInjuries.map(injury => (
                <div key={injury.id} className="bg-orange/10 rounded-xl p-4 border border-orange/20">
                  <div className="flex justify-between items-start mb-2">
                    <div>
                      <p className="font-medium text-text">{injury.bodyPart}</p>
                      <p className="text-xs text-text-secondary">{injury.phaseDescription}</p>
                    </div>
                    <span className={`text-xs px-2 py-1 rounded-lg ${
                      injury.severity === 'mild'
                        ? 'bg-yellow-500/20 text-yellow-400'
                        : injury.severity === 'moderate'
                        ? 'bg-orange/20 text-orange'
                        : 'bg-coral/20 text-coral'
                    }`}>
                      {injury.severity}
                    </span>
                  </div>
                  <div className="mb-2">
                    <div className="flex justify-between text-xs text-text-secondary mb-1">
                      <span>Recovery Progress</span>
                      <span className="font-semibold text-accent">{injury.progressPercent}%</span>
                    </div>
                    <ProgressBar current={injury.progressPercent} total={100} variant="glow" />
                  </div>
                  <p className="text-xs text-text-muted">{injury.daysRemaining} days remaining</p>
                </div>
              ))}
            </div>
          ) : (
            <div className="text-center py-4">
              <p className="text-text-muted text-sm">
                Tap "Report Injury" to let the AI coach know about any pain or injuries.
                It will automatically adjust your workouts.
              </p>
            </div>
          )}
        </GlassCard>

        {/* Quick Actions */}
        <div className="flex gap-3">
          <GlassButton
            variant="secondary"
            onClick={() => navigate('/profile')}
            fullWidth
          >
            Edit Profile
          </GlassButton>
          <GlassButton
            variant="primary"
            onClick={() => navigate('/chat')}
            fullWidth
          >
            Ask AI Coach
          </GlassButton>
        </div>

        {/* Footer Info */}
        <p className="text-center text-xs text-text-muted pt-4">
          Metrics are calculated based on your profile data.
          Update your profile for more accurate results.
        </p>
      </div>
    </DashboardLayout>
  );
}
