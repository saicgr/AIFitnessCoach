import { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { useMutation } from '@tanstack/react-query';
import { useAppStore, clearAppStorage } from '../store';
import { resetUser, calculateHealthMetrics, getActiveInjuries } from '../api/client';
import { createLogger } from '../utils/logger';
import type { HealthMetrics, ActiveInjury } from '../types';
import { GlassCard, GlassButton, ProgressBar } from '../components/ui';

const log = createLogger('settings');

// Icon components
const Icons = {
  Back: () => (
    <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 19l-7-7 7-7" />
    </svg>
  ),
  Heart: () => (
    <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4.318 6.318a4.5 4.5 0 000 6.364L12 20.364l7.682-7.682a4.5 4.5 0 00-6.364-6.364L12 7.636l-1.318-1.318a4.5 4.5 0 00-6.364 0z" />
    </svg>
  ),
  Scale: () => (
    <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M3 6l3 1m0 0l-3 9a5.002 5.002 0 006.001 0M6 7l3 9M6 7l6-2m6 2l3-1m-3 1l-3 9a5.002 5.002 0 006.001 0M18 7l3 9m-3-9l-6-2m0-2v2m0 16V5m0 16H9m3 0h3" />
    </svg>
  ),
  Target: () => (
    <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 12l2 2 4-4m5.618-4.016A11.955 11.955 0 0112 2.944a11.955 11.955 0 01-8.618 3.04A12.02 12.02 0 003 9c0 5.591 3.824 10.29 9 11.622 5.176-1.332 9-6.03 9-11.622 0-1.042-.133-2.052-.382-3.016z" />
    </svg>
  ),
  Warning: () => (
    <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z" />
    </svg>
  ),
  Trash: () => (
    <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" />
    </svg>
  ),
  Info: () => (
    <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
    </svg>
  ),
  Logout: () => (
    <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M17 16l4-4m0 0l-4-4m4 4H7m6 4v1a3 3 0 01-3 3H6a3 3 0 01-3-3V7a3 3 0 013-3h4a3 3 0 013 3v1" />
    </svg>
  ),
  Bandage: () => (
    <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M18.364 5.636l-3.536 3.536m0 5.656l3.536 3.536M9.172 9.172L5.636 5.636m3.536 9.192l-3.536 3.536M21 12a9 9 0 11-18 0 9 9 0 0118 0zm-5 0a4 4 0 11-8 0 4 4 0 018 0z" />
    </svg>
  ),
  Sun: () => (
    <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 3v1m0 16v1m9-9h-1M4 12H3m15.364 6.364l-.707-.707M6.343 6.343l-.707-.707m12.728 0l-.707.707M6.343 17.657l-.707.707M16 12a4 4 0 11-8 0 4 4 0 018 0z" />
    </svg>
  ),
  Moon: () => (
    <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M20.354 15.354A9 9 0 018.646 3.646 9.003 9.003 0 0012 21a9.003 9.003 0 008.354-5.646z" />
    </svg>
  ),
};

// Section Header component
function SectionHeader({ icon, title, subtitle }: { icon: React.ReactNode; title: string; subtitle?: string }) {
  return (
    <div className="flex items-center gap-3 mb-4">
      <div className="p-2 bg-primary/20 rounded-xl text-primary">
        {icon}
      </div>
      <div>
        <h2 className="text-lg font-semibold text-text">{title}</h2>
        {subtitle && <p className="text-xs text-text-secondary">{subtitle}</p>}
      </div>
    </div>
  );
}

// Metric Card component
function MetricCard({
  label,
  value,
  unit,
  sublabel,
  color = 'primary',
}: {
  label: string;
  value: string | number;
  unit?: string;
  sublabel?: string;
  color?: 'primary' | 'secondary' | 'accent' | 'orange';
}) {
  const colorClasses = {
    primary: 'bg-primary/10 border-primary/20 text-primary',
    secondary: 'bg-secondary/10 border-secondary/20 text-secondary',
    accent: 'bg-accent/10 border-accent/20 text-accent',
    orange: 'bg-orange/10 border-orange/20 text-orange',
  };

  return (
    <div className={`rounded-xl p-4 border ${colorClasses[color]} transition-all hover:scale-[1.02]`}>
      <p className={`text-xs font-medium mb-1 opacity-80`}>{label}</p>
      <div className="flex items-baseline gap-1">
        <span className="text-xl font-bold text-text">{value}</span>
        {unit && <span className="text-sm text-text-secondary">{unit}</span>}
      </div>
      {sublabel && <p className="text-xs text-text-muted mt-1">{sublabel}</p>}
    </div>
  );
}

// Chip component
function Chip({ children, variant = 'primary' }: { children: React.ReactNode; variant?: 'primary' | 'secondary' }) {
  const classes = {
    primary: 'bg-primary/20 text-primary border-primary/30',
    secondary: 'bg-accent/20 text-accent border-accent/30',
  };

  return (
    <span className={`inline-flex items-center px-3 py-1 rounded-full text-sm font-medium border ${classes[variant]}`}>
      {children}
    </span>
  );
}

export default function Settings() {
  const navigate = useNavigate();
  const { user, onboardingData, setOnboardingData, theme, toggleTheme, setUser } = useAppStore();
  const [showResetDialog, setShowResetDialog] = useState(false);
  const [resetError, setResetError] = useState<string | null>(null);
  const [healthMetrics, setHealthMetrics] = useState<HealthMetrics | null>(null);
  const [metricsLoading, setMetricsLoading] = useState(false);
  const [activeInjuries, setActiveInjuries] = useState<ActiveInjury[]>([]);
  const [injuriesLoading, setInjuriesLoading] = useState(false);

  // Calculate health metrics when component loads
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

  // Fetch active injuries
  useEffect(() => {
    const fetchInjuries = async () => {
      if (!user) return;

      setInjuriesLoading(true);
      try {
        const injuries = await getActiveInjuries(user.id);
        setActiveInjuries(injuries);
        log.info('Active injuries fetched', injuries);
      } catch (error) {
        log.error('Failed to fetch injuries', error);
      } finally {
        setInjuriesLoading(false);
      }
    };

    fetchInjuries();
  }, [user]);


  const resetMutation = useMutation({
    mutationFn: async () => {
      if (!user) throw new Error('No user found');
      log.info('Starting full reset for user', { userId: user.id });
      await resetUser(user.id);
      log.info('Backend reset successful');
    },
    onSuccess: () => {
      log.info('Reset successful, clearing local storage');
      clearAppStorage();
      navigate('/login', { replace: true });
    },
    onError: (error: Error) => {
      log.error('Reset failed', error);
      setResetError(error.message || 'Failed to reset data. Please try again.');
    },
  });

  const handleResetClick = () => {
    setResetError(null);
    setShowResetDialog(true);
  };

  const handleConfirmReset = () => {
    resetMutation.mutate();
  };

  const handleCancelReset = () => {
    setShowResetDialog(false);
    setResetError(null);
  };

  const handleGenderSelect = async (gender: 'male' | 'female') => {
    setOnboardingData({ gender });
    if (!user || !onboardingData.weightKg || !onboardingData.heightCm || !onboardingData.age) return;

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
      log.info('Health metrics calculated after gender selection', metrics);
    } catch (error) {
      log.error('Failed to calculate health metrics', error);
    } finally {
      setMetricsLoading(false);
    }
  };

  if (!user) {
    navigate('/onboarding');
    return null;
  }

  const userInitials = onboardingData.name
    ? onboardingData.name.split(' ').map(n => n[0]).join('').toUpperCase().slice(0, 2)
    : 'U';

  return (
    <div className="min-h-screen bg-background pb-24">
      {/* Background decorations */}
      <div className="fixed inset-0 overflow-hidden pointer-events-none">
        <div className="absolute top-0 right-0 w-[400px] h-[400px] bg-primary/5 rounded-full blur-3xl" />
        <div className="absolute bottom-1/4 left-0 w-[300px] h-[300px] bg-secondary/5 rounded-full blur-3xl" />
      </div>

      {/* Header */}
      <header className="relative z-10 glass-heavy safe-area-top">
        <div className="max-w-2xl mx-auto px-4 py-4 flex items-center justify-between">
          <button
            onClick={() => navigate(-1)}
            className="p-2 hover:bg-white/10 rounded-xl transition-colors text-text-secondary hover:text-text"
          >
            <Icons.Back />
          </button>
          <h1 className="text-lg font-semibold text-text">Settings</h1>
          <div className="w-9" />
        </div>
      </header>

      <main className="relative z-10 max-w-2xl mx-auto px-4 py-6 space-y-6">
        {/* Profile Card */}
        <div
          className="relative overflow-hidden rounded-2xl p-6 bg-gradient-to-br from-primary to-secondary"
          style={{
            boxShadow: '0 0 40px rgba(6, 182, 212, 0.3), 0 20px 40px rgba(0,0,0,0.3)',
          }}
        >
          <div className="flex items-center gap-4">
            <div className="w-16 h-16 bg-white/20 backdrop-blur rounded-2xl flex items-center justify-center text-xl font-bold text-white">
              {userInitials}
            </div>
            <div className="flex-1">
              <h2 className="text-xl font-bold text-white">{onboardingData.name || 'Fitness Enthusiast'}</h2>
              <p className="text-white/70 text-sm capitalize">{user.fitness_level} Level</p>
            </div>
          </div>

          <div className="grid grid-cols-3 gap-3 mt-6">
            <div className="bg-white/10 backdrop-blur rounded-xl p-3 text-center">
              <p className="text-2xl font-bold text-white">{onboardingData.age}</p>
              <p className="text-xs text-white/70">Age</p>
            </div>
            <div className="bg-white/10 backdrop-blur rounded-xl p-3 text-center">
              <p className="text-2xl font-bold text-white">{onboardingData.weightKg}</p>
              <p className="text-xs text-white/70">kg</p>
            </div>
            <div className="bg-white/10 backdrop-blur rounded-xl p-3 text-center">
              <p className="text-2xl font-bold text-white">{onboardingData.heightCm}</p>
              <p className="text-xs text-white/70">cm</p>
            </div>
          </div>
        </div>

        {/* Appearance Section */}
        <GlassCard className="p-6">
          <SectionHeader
            icon={theme === 'dark' ? <Icons.Moon /> : <Icons.Sun />}
            title="Appearance"
            subtitle="Customize your experience"
          />

          <div className="flex items-center justify-between py-3">
            <div className="flex items-center gap-3">
              <div className="p-2 bg-white/5 rounded-xl">
                {theme === 'dark' ? <Icons.Moon /> : <Icons.Sun />}
              </div>
              <div>
                <p className="font-medium text-text">Dark Mode</p>
                <p className="text-xs text-text-secondary">
                  {theme === 'dark' ? 'Currently using dark theme' : 'Currently using light theme'}
                </p>
              </div>
            </div>

            {/* Toggle Switch */}
            <button
              onClick={toggleTheme}
              className={`relative w-14 h-8 rounded-full transition-all duration-300 ${
                theme === 'dark'
                  ? 'bg-primary shadow-[0_0_15px_rgba(6,182,212,0.4)]'
                  : 'bg-white/20 border border-white/30'
              }`}
            >
              <div
                className={`absolute top-1 w-6 h-6 rounded-full transition-all duration-300 flex items-center justify-center ${
                  theme === 'dark'
                    ? 'left-7 bg-white text-primary'
                    : 'left-1 bg-white text-orange'
                }`}
              >
                {theme === 'dark' ? (
                  <svg className="w-3.5 h-3.5" fill="currentColor" viewBox="0 0 24 24">
                    <path d="M20.354 15.354A9 9 0 018.646 3.646 9.003 9.003 0 0012 21a9.003 9.003 0 008.354-5.646z" />
                  </svg>
                ) : (
                  <svg className="w-3.5 h-3.5" fill="currentColor" viewBox="0 0 24 24">
                    <path d="M12 3v1m0 16v1m9-9h-1M4 12H3m15.364 6.364l-.707-.707M6.343 6.343l-.707-.707m12.728 0l-.707.707M6.343 17.657l-.707.707M16 12a4 4 0 11-8 0 4 4 0 018 0z" />
                  </svg>
                )}
              </div>
            </button>
          </div>
        </GlassCard>

        {/* Goals & Equipment Section */}
        <GlassCard className="p-6">
          <SectionHeader icon={<Icons.Target />} title="Goals & Equipment" />

          <div className="space-y-4">
            <div>
              <p className="text-xs font-medium text-text-secondary uppercase tracking-wide mb-2">Your Goals</p>
              <div className="flex flex-wrap gap-2">
                {user.goals.length > 0 ? (
                  user.goals.map((goal) => (
                    <Chip key={goal} variant="primary">{goal}</Chip>
                  ))
                ) : (
                  <span className="text-text-muted text-sm">No goals set</span>
                )}
              </div>
            </div>

            <div className="border-t border-white/10 pt-4">
              <p className="text-xs font-medium text-text-secondary uppercase tracking-wide mb-2">Available Equipment</p>
              <div className="flex flex-wrap gap-2">
                {user.equipment.length > 0 ? (
                  user.equipment.map((item) => (
                    <Chip key={item} variant="secondary">{item}</Chip>
                  ))
                ) : (
                  <span className="text-text-muted text-sm">Bodyweight only</span>
                )}
              </div>
            </div>
          </div>
        </GlassCard>

        {/* Health Metrics Section */}
        <GlassCard className="p-6">
          <SectionHeader
            icon={<Icons.Heart />}
            title="Health Metrics"
            subtitle="Based on your measurements"
          />

          {metricsLoading ? (
            <div className="flex flex-col items-center justify-center py-12">
              <div className="w-10 h-10 border-3 border-primary border-t-transparent rounded-full animate-spin mb-3" />
              <p className="text-text-secondary text-sm">Calculating your metrics...</p>
            </div>
          ) : healthMetrics ? (
            <div className="space-y-5">
              {/* BMI Card */}
              <div className="bg-white/5 rounded-xl p-5 border border-white/10">
                <div className="flex justify-between items-start mb-4">
                  <div>
                    <p className="text-sm font-medium text-text-secondary">Body Mass Index</p>
                    <p className="text-3xl font-bold text-text mt-1">{healthMetrics.bmi.toFixed(1)}</p>
                  </div>
                  <span className={`text-xs font-semibold px-3 py-1.5 rounded-lg ${
                    healthMetrics.bmiCategory === 'normal'
                      ? 'bg-accent/20 text-accent'
                      : healthMetrics.bmiCategory === 'underweight'
                      ? 'bg-orange/20 text-orange'
                      : healthMetrics.bmiCategory === 'overweight'
                      ? 'bg-orange/20 text-orange'
                      : 'bg-coral/20 text-coral'
                  }`}>
                    {healthMetrics.bmiCategory.charAt(0).toUpperCase() + healthMetrics.bmiCategory.slice(1)}
                  </span>
                </div>
                <ProgressBar current={healthMetrics.bmi} total={40} variant="glow" />
                <div className="flex justify-between text-xs text-text-muted mt-2">
                  <span>18.5</span>
                  <span>25</span>
                  <span>30</span>
                  <span>40</span>
                </div>
              </div>

              {/* Metabolic Rates Grid */}
              <div className="grid grid-cols-2 gap-3">
                <MetricCard
                  label="Basal Metabolic Rate"
                  value={Math.round(healthMetrics.bmrMifflin)}
                  unit="kcal"
                  sublabel="Daily at rest"
                  color="primary"
                />
                <MetricCard
                  label="Daily Energy Needs"
                  value={Math.round(healthMetrics.tdee)}
                  unit="kcal"
                  sublabel="TDEE"
                  color="accent"
                />
              </div>

              {/* Ideal Body Weight */}
              <div className="bg-secondary/10 rounded-xl p-4 border border-secondary/20">
                <div className="flex items-center gap-2 mb-3">
                  <Icons.Scale />
                  <p className="text-sm font-medium text-secondary">Ideal Body Weight Range</p>
                </div>
                <div className="flex items-center justify-between">
                  <div className="text-center">
                    <p className="text-xl font-bold text-text">{Math.round(healthMetrics.idealBodyWeightMiller)}</p>
                    <p className="text-xs text-text-secondary">Min (kg)</p>
                  </div>
                  <div className="flex-1 mx-4 h-1 bg-white/10 rounded-full relative">
                    <div className="absolute inset-y-0 left-1/4 right-1/4 bg-secondary rounded-full" />
                  </div>
                  <div className="text-center">
                    <p className="text-xl font-bold text-text">{Math.round(healthMetrics.idealBodyWeightDevine)}</p>
                    <p className="text-xs text-text-secondary">Max (kg)</p>
                  </div>
                </div>
              </div>

              {/* Body Composition */}
              {(healthMetrics.bodyFatNavy || healthMetrics.waistToHeightRatio) && (
                <div>
                  <p className="text-xs font-medium text-text-secondary uppercase tracking-wide mb-3">Body Composition</p>
                  <div className="grid grid-cols-2 gap-3">
                    {healthMetrics.bodyFatNavy && (
                      <MetricCard
                        label="Est. Body Fat"
                        value={healthMetrics.bodyFatNavy.toFixed(1)}
                        unit="%"
                        color="orange"
                      />
                    )}
                    {healthMetrics.leanBodyMass && (
                      <MetricCard
                        label="Lean Mass"
                        value={healthMetrics.leanBodyMass.toFixed(1)}
                        unit="kg"
                        color="orange"
                      />
                    )}
                    {healthMetrics.waistToHeightRatio && (
                      <MetricCard
                        label="Waist/Height"
                        value={healthMetrics.waistToHeightRatio.toFixed(2)}
                        color="orange"
                      />
                    )}
                    {healthMetrics.ffmi && (
                      <MetricCard
                        label="FFMI"
                        value={healthMetrics.ffmi.toFixed(1)}
                        color="orange"
                      />
                    )}
                  </div>
                </div>
              )}
            </div>
          ) : (
            <div className="text-center py-6">
              <div className="w-12 h-12 bg-white/5 rounded-full flex items-center justify-center mx-auto mb-3">
                <Icons.Info />
              </div>
              <p className="text-text font-medium mb-1">Metrics Not Available</p>
              <p className="text-text-secondary text-sm mb-4">
                Select your biological sex to calculate health metrics
              </p>
              <div className="flex gap-3 justify-center">
                <button
                  onClick={() => handleGenderSelect('male')}
                  className={`px-6 py-2.5 rounded-xl font-medium transition-all ${
                    onboardingData.gender === 'male'
                      ? 'bg-primary text-white shadow-[0_0_20px_rgba(6,182,212,0.4)]'
                      : 'bg-white/5 text-text-secondary hover:bg-white/10 border border-white/10'
                  }`}
                >
                  Male
                </button>
                <button
                  onClick={() => handleGenderSelect('female')}
                  className={`px-6 py-2.5 rounded-xl font-medium transition-all ${
                    onboardingData.gender === 'female'
                      ? 'bg-primary text-white shadow-[0_0_20px_rgba(6,182,212,0.4)]'
                      : 'bg-white/5 text-text-secondary hover:bg-white/10 border border-white/10'
                  }`}
                >
                  Female
                </button>
              </div>
              <p className="text-xs text-text-muted mt-3">
                Used only for accurate BMR and body composition calculations
              </p>
            </div>
          )}
        </GlassCard>

        {/* Active Injuries Section */}
        {(injuriesLoading || activeInjuries.length > 0) && (
          <GlassCard className="p-6 border-orange/30">
            <SectionHeader
              icon={<Icons.Bandage />}
              title="Active Injuries"
              subtitle="Currently being tracked"
            />

            {injuriesLoading ? (
              <div className="flex items-center justify-center py-8">
                <div className="w-8 h-8 border-2 border-orange border-t-transparent rounded-full animate-spin" />
              </div>
            ) : (
              <div className="space-y-4">
                {activeInjuries.map((injury) => (
                  <div key={injury.id} className="bg-orange/10 rounded-xl p-4 border border-orange/20">
                    <div className="flex justify-between items-start mb-3">
                      <div>
                        <p className="font-semibold text-text">{injury.bodyPart}</p>
                        <p className="text-sm text-text-secondary">{injury.phaseDescription}</p>
                      </div>
                      <span className={`text-xs font-semibold px-2.5 py-1 rounded-lg ${
                        injury.severity === 'mild'
                          ? 'bg-yellow-500/20 text-yellow-400'
                          : injury.severity === 'moderate'
                          ? 'bg-orange/20 text-orange'
                          : 'bg-coral/20 text-coral'
                      }`}>
                        {injury.severity}
                      </span>
                    </div>

                    <div className="mb-3">
                      <div className="flex justify-between text-xs text-text-secondary mb-1.5">
                        <span>Recovery Progress</span>
                        <span className="font-semibold text-accent">{injury.progressPercent}%</span>
                      </div>
                      <ProgressBar current={injury.progressPercent} total={100} variant="glow" />
                    </div>

                    <div className="flex justify-between text-xs text-text-muted">
                      <span>Day {injury.daysSinceInjury} of recovery</span>
                      <span>{injury.daysRemaining} days remaining</span>
                    </div>

                    {injury.rehabExercises.length > 0 && (
                      <div className="mt-3 pt-3 border-t border-orange/20">
                        <p className="text-xs font-medium text-orange mb-2">Recommended Rehab</p>
                        <div className="flex flex-wrap gap-1.5">
                          {injury.rehabExercises.slice(0, 3).map((exercise, idx) => (
                            <span key={idx} className="text-xs bg-white/5 text-text-secondary px-2 py-1 rounded-lg border border-white/10">
                              {exercise}
                            </span>
                          ))}
                        </div>
                      </div>
                    )}
                  </div>
                ))}

                <p className="text-xs text-text-muted text-center pt-2">
                  Tell the AI coach when you're feeling better to update injury status
                </p>
              </div>
            )}
          </GlassCard>
        )}

        {/* App Info Section */}
        <GlassCard className="p-6">
          <SectionHeader icon={<Icons.Info />} title="About" />
          <div className="space-y-3">
            <div className="flex justify-between items-center py-2">
              <span className="text-text-secondary">App Name</span>
              <span className="font-medium text-text">AI Fitness Coach</span>
            </div>
            <div className="border-t border-white/10" />
            <div className="flex justify-between items-center py-2">
              <span className="text-text-secondary">Version</span>
              <span className="font-medium text-text">1.0.0</span>
            </div>
          </div>
        </GlassCard>

        {/* Logout Section */}
        <GlassCard className="p-6">
          <div className="flex items-center gap-3 mb-4">
            <div className="p-2 bg-orange/20 rounded-xl text-orange">
              <Icons.Logout />
            </div>
            <div>
              <h2 className="text-lg font-semibold text-text">Account</h2>
              <p className="text-xs text-text-secondary">Sign out of your account</p>
            </div>
          </div>

          <p className="text-sm text-text-secondary mb-4">
            Logging out will keep your data saved. You can log back in anytime to continue your fitness journey.
          </p>

          <GlassButton
            variant="secondary"
            onClick={() => {
              log.info('User logging out');
              setUser(null);
              navigate('/login', { replace: true });
            }}
            fullWidth
            icon={<Icons.Logout />}
          >
            Log Out
          </GlassButton>
        </GlassCard>

        {/* Danger Zone */}
        <GlassCard className="p-6 border-coral/30">
          <div className="flex items-center gap-3 mb-4">
            <div className="p-2 bg-coral/20 rounded-xl text-coral">
              <Icons.Trash />
            </div>
            <div>
              <h2 className="text-lg font-semibold text-coral">Danger Zone</h2>
              <p className="text-xs text-text-secondary">Irreversible actions</p>
            </div>
          </div>

          <p className="text-sm text-text-secondary mb-4">
            Resetting will permanently delete all your data including workouts, progress, and chat history.
          </p>

          <GlassButton
            variant="danger"
            onClick={handleResetClick}
            disabled={resetMutation.isPending}
            loading={resetMutation.isPending}
            fullWidth
            icon={<Icons.Trash />}
          >
            Reset All Data
          </GlassButton>

          {resetError && (
            <div className="mt-3 p-3 bg-coral/10 border border-coral/30 rounded-xl flex items-start gap-2">
              <Icons.Warning />
              <p className="text-coral text-sm flex-1">{resetError}</p>
            </div>
          )}
        </GlassCard>
      </main>

      {/* Reset Confirmation Dialog */}
      {showResetDialog && (
        <div className="fixed inset-0 bg-black/70 backdrop-blur-sm flex items-center justify-center z-50 p-4">
          <GlassCard className="max-w-md w-full p-6" variant="elevated">
            <div className="text-center mb-5">
              <div className="w-16 h-16 bg-coral/20 rounded-2xl flex items-center justify-center mx-auto mb-4">
                <svg className="w-8 h-8 text-coral" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z" />
                </svg>
              </div>
              <h2 className="text-xl font-bold text-text mb-2">Reset All Data?</h2>
              <p className="text-text-secondary text-sm">This will permanently delete:</p>
            </div>

            <ul className="space-y-2 mb-5">
              {[
                'All your workouts and progress',
                'Your preferences and goals',
                'Chat history with AI coach'
              ].map((item, i) => (
                <li key={i} className="flex items-center gap-3 bg-coral/10 p-3 rounded-xl border border-coral/20">
                  <div className="w-5 h-5 bg-coral/30 rounded-full flex items-center justify-center">
                    <span className="text-coral text-xs font-bold">×</span>
                  </div>
                  <span className="text-text-secondary text-sm">{item}</span>
                </li>
              ))}
            </ul>

            <p className="text-center text-sm text-text font-medium mb-5 p-3 bg-white/5 rounded-xl border border-white/10">
              You will be taken back to onboarding.
              <br />
              <span className="text-coral">This action cannot be undone.</span>
            </p>

            {resetError && (
              <div className="mb-4 p-3 bg-coral/10 border border-coral/30 rounded-xl">
                <p className="text-coral text-sm">{resetError}</p>
              </div>
            )}

            <div className="flex gap-3">
              <GlassButton
                variant="secondary"
                onClick={handleCancelReset}
                disabled={resetMutation.isPending}
                fullWidth
              >
                Cancel
              </GlassButton>
              <GlassButton
                variant="danger"
                onClick={handleConfirmReset}
                loading={resetMutation.isPending}
                fullWidth
              >
                Reset Everything
              </GlassButton>
            </div>
          </GlassCard>
        </div>
      )}
    </div>
  );
}
