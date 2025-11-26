import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { useMutation } from '@tanstack/react-query';
import { useAppStore } from '../store';
import { createUser, updateUser, generateWorkout } from '../api/client';
import { createLogger } from '../utils/logger';
import { GlassCard, GlassButton, GlassInput, SelectionChip, ProgressBar } from '../components/ui';

const log = createLogger('onboarding');

// Icons
const Icons = {
  Dumbbell: () => (
    <svg className="w-8 h-8" fill="none" stroke="currentColor" viewBox="0 0 24 24">
      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M4 6h2v12H4V6zm14 0h2v12h-2V6zM2 9h4v6H2V9zm16 0h4v6h-4V9zM6 11h12v2H6v-2z" />
    </svg>
  ),
  User: () => (
    <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z" />
    </svg>
  ),
  Scale: () => (
    <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M3 6l3 1m0 0l-3 9a5.002 5.002 0 006.001 0M6 7l3 9M6 7l6-2m6 2l3-1m-3 1l-3 9a5.002 5.002 0 006.001 0M18 7l3 9m-3-9l-6-2m0-2v2m0 16V5m0 16H9m3 0h3" />
    </svg>
  ),
  Target: () => (
    <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M9 12l2 2 4-4m5.618-4.016A11.955 11.955 0 0112 2.944a11.955 11.955 0 01-8.618 3.04A12.02 12.02 0 003 9c0 5.591 3.824 10.29 9 11.622 5.176-1.332 9-6.03 9-11.622 0-1.042-.133-2.052-.382-3.016z" />
    </svg>
  ),
  Calendar: () => (
    <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z" />
    </svg>
  ),
  Cog: () => (
    <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M10.325 4.317c.426-1.756 2.924-1.756 3.35 0a1.724 1.724 0 002.573 1.066c1.543-.94 3.31.826 2.37 2.37a1.724 1.724 0 001.065 2.572c1.756.426 1.756 2.924 0 3.35a1.724 1.724 0 00-1.066 2.573c.94 1.543-.826 3.31-2.37 2.37a1.724 1.724 0 00-2.572 1.065c-.426 1.756-2.924 1.756-3.35 0a1.724 1.724 0 00-2.573-1.066c-1.543.94-3.31-.826-2.37-2.37a1.724 1.724 0 00-1.065-2.572c-1.756-.426-1.756-2.924 0-3.35a1.724 1.724 0 001.066-2.573c-.94-1.543.826-3.31 2.37-2.37.996.608 2.296.07 2.572-1.065z" />
      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" />
    </svg>
  ),
  Heart: () => (
    <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M4.318 6.318a4.5 4.5 0 000 6.364L12 20.364l7.682-7.682a4.5 4.5 0 00-6.364-6.364L12 7.636l-1.318-1.318a4.5 4.5 0 00-6.364 0z" />
    </svg>
  ),
  Sunrise: () => (
    <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M12 3v1m0 16v1m9-9h-1M4 12H3m15.364 6.364l-.707-.707M6.343 6.343l-.707-.707m12.728 0l-.707.707M6.343 17.657l-.707.707M16 12a4 4 0 11-8 0 4 4 0 018 0z" />
    </svg>
  ),
  Sun: () => (
    <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M12 3v1m0 16v1m9-9h-1M4 12H3m15.364 6.364l-.707-.707M6.343 6.343l-.707-.707m12.728 0l-.707.707M6.343 17.657l-.707.707M16 12a4 4 0 11-8 0 4 4 0 018 0z" />
    </svg>
  ),
  Moon: () => (
    <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M20.354 15.354A9 9 0 018.646 3.646 9.003 9.003 0 0012 21a9.003 9.003 0 008.354-5.646z" />
    </svg>
  ),
  ChevronDown: () => (
    <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 9l-7 7-7-7" />
    </svg>
  ),
  Sparkles: () => (
    <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M5 3v4M3 5h4M6 17v4m-2-2h4m5-16l2.286 6.857L21 12l-5.714 2.143L13 21l-2.286-6.857L5 12l5.714-2.143L13 3z" />
    </svg>
  ),
};

// Constants
const GENDERS = [
  { id: 'male', label: 'Male', icon: '♂️' },
  { id: 'female', label: 'Female', icon: '♀️' },
] as const;

const FITNESS_LEVELS = [
  { id: 'beginner', label: 'Beginner', desc: 'New to fitness or returning after a break', icon: '🌱' },
  { id: 'intermediate', label: 'Intermediate', desc: 'Regular exercise for 6+ months', icon: '💪' },
  { id: 'advanced', label: 'Advanced', desc: 'Consistent training for 2+ years', icon: '🔥' },
] as const;

const GOALS = [
  'Build Muscle',
  'Lose Weight',
  'Increase Strength',
  'Improve Endurance',
  'Stay Active',
  'Flexibility',
  'Athletic Performance',
  'General Health',
];

const WORKOUT_EXPERIENCE = [
  'Weight Training',
  'Cardio',
  'HIIT',
  'Yoga/Pilates',
  'CrossFit',
  'Calisthenics',
  'Sports',
  'None',
];

const DAYS_OF_WEEK = [
  { id: 0, short: 'M', label: 'Monday' },
  { id: 1, short: 'T', label: 'Tuesday' },
  { id: 2, short: 'W', label: 'Wednesday' },
  { id: 3, short: 'T', label: 'Thursday' },
  { id: 4, short: 'F', label: 'Friday' },
  { id: 5, short: 'S', label: 'Saturday' },
  { id: 6, short: 'S', label: 'Sunday' },
];

const PREFERRED_TIMES = [
  { id: 'morning', label: 'Morning', Icon: Icons.Sunrise },
  { id: 'afternoon', label: 'Afternoon', Icon: Icons.Sun },
  { id: 'evening', label: 'Evening', Icon: Icons.Moon },
] as const;

const WORKOUT_DURATIONS = [30, 45, 60, 75, 90];

const TRAINING_SPLITS = [
  { id: 'full_body', label: 'Full Body', desc: 'Work all muscle groups each session' },
  { id: 'upper_lower', label: 'Upper/Lower', desc: 'Alternate between upper and lower body' },
  { id: 'push_pull_legs', label: 'Push/Pull/Legs', desc: 'Split by movement patterns' },
  { id: 'body_part', label: 'Body Part Split', desc: 'Focus on one muscle group per session' },
] as const;

const INTENSITY_LEVELS = [
  { id: 'light', label: 'Light', desc: 'Moderate effort, plenty of rest' },
  { id: 'moderate', label: 'Moderate', desc: 'Challenging but sustainable' },
  { id: 'intense', label: 'Intense', desc: 'Push your limits' },
] as const;

const EQUIPMENT = [
  'Bodyweight Only',
  'Dumbbells',
  'Barbell',
  'Resistance Bands',
  'Pull-up Bar',
  'Kettlebell',
  'Cable Machine',
  'Full Gym',
];

const WORKOUT_VARIETY = [
  { id: 'consistent', label: 'Consistent', desc: 'Same exercises each week for progression tracking' },
  { id: 'varied', label: 'Varied', desc: 'Mix it up with different exercises each week' },
] as const;

const INJURY_OPTIONS = [
  'Lower back pain',
  'Shoulder issues',
  'Knee problems',
  'Wrist/elbow pain',
  'Neck pain',
  'Hip issues',
  'None',
];

const HEALTH_CONDITIONS = [
  'High blood pressure',
  'Heart condition',
  'Diabetes',
  'Asthma',
  'Arthritis',
  'Pregnancy',
  'Recent surgery',
  'None',
];

const ACTIVITY_LEVELS = [
  { id: 'sedentary', label: 'Sedentary', desc: 'Mostly sitting, minimal activity' },
  { id: 'lightly_active', label: 'Lightly Active', desc: 'Light activity, walking occasionally' },
  { id: 'moderately_active', label: 'Moderately Active', desc: 'Regular activity, some exercise' },
  { id: 'very_active', label: 'Very Active', desc: 'Physically demanding job or daily exercise' },
] as const;

// Step metadata
const STEPS = [
  { title: 'Personal Info', Icon: Icons.User },
  { title: 'Body Metrics', Icon: Icons.Scale },
  { title: 'Fitness Background', Icon: Icons.Target },
  { title: 'Schedule', Icon: Icons.Calendar },
  { title: 'Preferences', Icon: Icons.Cog },
  { title: 'Health', Icon: Icons.Heart },
];

// Unit conversion helpers
const cmToFeetInches = (cm: number) => {
  const totalInches = cm / 2.54;
  const feet = Math.floor(totalInches / 12);
  const inches = Math.round(totalInches % 12);
  return { feet, inches };
};

const feetInchesToCm = (feet: number, inches: number) => {
  return Math.round((feet * 12 + inches) * 2.54);
};

const kgToLbs = (kg: number) => Math.round(kg * 2.205);
const lbsToKg = (lbs: number) => Math.round(lbs / 2.205);

export default function Onboarding() {
  const navigate = useNavigate();
  const { onboardingData, setOnboardingData, setUser, user } = useAppStore();
  const [step, setStep] = useState(0);
  const [isGenerating, setIsGenerating] = useState(false);
  const [generationProgress, setGenerationProgress] = useState('');

  // Unit toggle states
  const [useMetricHeight, setUseMetricHeight] = useState(true);
  const [useMetricWeight, setUseMetricWeight] = useState(true);

  // Imperial height state
  const [heightFeet, setHeightFeet] = useState(5);
  const [heightInches, setHeightInches] = useState(7);

  // String state for number inputs
  const [heightCmStr, setHeightCmStr] = useState(String(onboardingData.heightCm));
  const [heightFeetStr, setHeightFeetStr] = useState('5');
  const [heightInchesStr, setHeightInchesStr] = useState('7');
  const [weightStr, setWeightStr] = useState(String(onboardingData.weightKg));
  const [targetWeightStr, setTargetWeightStr] = useState(
    onboardingData.targetWeightKg ? String(onboardingData.targetWeightKg) : ''
  );

  // Advanced measurements state
  const [showAdvancedMeasurements, setShowAdvancedMeasurements] = useState(false);

  // Validation errors
  const [errors, setErrors] = useState<Record<string, string>>({});
  const [waistStr, setWaistStr] = useState(
    onboardingData.waistCircumferenceCm ? String(onboardingData.waistCircumferenceCm) : ''
  );
  const [hipStr, setHipStr] = useState(
    onboardingData.hipCircumferenceCm ? String(onboardingData.hipCircumferenceCm) : ''
  );
  const [neckStr, setNeckStr] = useState(
    onboardingData.neckCircumferenceCm ? String(onboardingData.neckCircumferenceCm) : ''
  );
  const [bodyFatStr, setBodyFatStr] = useState(
    onboardingData.bodyFatPercent ? String(onboardingData.bodyFatPercent) : ''
  );
  const [restingHRStr, setRestingHRStr] = useState(
    onboardingData.restingHeartRate ? String(onboardingData.restingHeartRate) : ''
  );
  const [bpSystolicStr, setBpSystolicStr] = useState(
    onboardingData.bloodPressureSystolic ? String(onboardingData.bloodPressureSystolic) : ''
  );
  const [bpDiastolicStr, setBpDiastolicStr] = useState(
    onboardingData.bloodPressureDiastolic ? String(onboardingData.bloodPressureDiastolic) : ''
  );

  const createUserMutation = useMutation({
    mutationFn: async () => {
      log.info('Creating/updating user', onboardingData);

      const preferences = JSON.stringify({
        days_per_week: onboardingData.daysPerWeek,
        workout_duration: onboardingData.workoutDuration,
        training_split: onboardingData.trainingSplit,
        intensity_preference: onboardingData.intensityPreference,
        preferred_time: onboardingData.preferredTime,
        selected_days: onboardingData.selectedDays,
        workout_variety: onboardingData.workoutVariety,
        activity_level: onboardingData.activityLevel,
        name: onboardingData.name,
        gender: onboardingData.gender,
        age: onboardingData.age,
        height_cm: onboardingData.heightCm,
        weight_kg: onboardingData.weightKg,
        target_weight_kg: onboardingData.targetWeightKg,
        workout_experience: onboardingData.workoutExperience,
        health_conditions: onboardingData.healthConditions,
        waist_circumference_cm: onboardingData.waistCircumferenceCm,
        hip_circumference_cm: onboardingData.hipCircumferenceCm,
        neck_circumference_cm: onboardingData.neckCircumferenceCm,
        body_fat_percent: onboardingData.bodyFatPercent,
        resting_heart_rate: onboardingData.restingHeartRate,
        blood_pressure_systolic: onboardingData.bloodPressureSystolic,
        blood_pressure_diastolic: onboardingData.bloodPressureDiastolic,
      });

      if (user) {
        return updateUser(user.id, {
          fitness_level: onboardingData.fitnessLevel,
          goals: JSON.stringify(onboardingData.goals),
          equipment: JSON.stringify(onboardingData.equipment),
          preferences,
          active_injuries: JSON.stringify(onboardingData.activeInjuries),
          onboarding_completed: true,
        });
      }
      return createUser({
        fitness_level: onboardingData.fitnessLevel,
        goals: JSON.stringify(onboardingData.goals),
        equipment: JSON.stringify(onboardingData.equipment),
        preferences,
        active_injuries: JSON.stringify(onboardingData.activeInjuries),
      });
    },
    onSuccess: async (data) => {
      log.info(`User ${user ? 'updated' : 'created'}: id=${data.id}`);
      setUser(data);

      setIsGenerating(true);
      setGenerationProgress('Setting up your workout schedule...');

      try {
        const today = new Date();
        const todayDate = today.toISOString().split('T')[0];

        // Convert JS day (0=Sun) to our format (0=Mon)
        const todayJsDay = today.getDay(); // 0=Sun, 1=Mon, ..., 6=Sat
        const todayIndex = todayJsDay === 0 ? 6 : todayJsDay - 1; // Convert to 0=Mon, ..., 6=Sun

        // Check if today is a selected workout day
        const isTodayWorkoutDay = onboardingData.selectedDays.includes(todayIndex);

        log.info(`Checking workout day for user ${data.id}`, {
          todayJsDay,
          todayIndex,
          selectedDays: onboardingData.selectedDays,
          isTodayWorkoutDay,
          duration: onboardingData.workoutDuration,
        });

        if (isTodayWorkoutDay) {
          // Today is a workout day, generate today's workout
          setGenerationProgress('Creating your first workout...');

          await generateWorkout({
            user_id: data.id,
            duration_minutes: onboardingData.workoutDuration,
            fitness_level: onboardingData.fitnessLevel,
            goals: onboardingData.goals,
            equipment: onboardingData.equipment,
          });

          log.info('First workout generated for today');
          setGenerationProgress('Your first workout is ready!');
        } else {
          // Today is not a workout day, skip first workout generation
          log.info('Today is not a workout day, skipping first workout generation');
          setGenerationProgress('Your schedule is ready!');
        }

        // Store pending generation for background processing of remaining workouts
        localStorage.setItem('pendingWorkoutGeneration', JSON.stringify({
          user_id: data.id,
          month_start_date: todayDate,
          selected_days: onboardingData.selectedDays,
          duration_minutes: onboardingData.workoutDuration,
        }));

        setTimeout(() => {
          navigate('/');
        }, 1000);
      } catch (error) {
        log.error('Failed to generate first workout', error);
        setGenerationProgress('Could not generate workout. Redirecting...');

        const fallbackToday = new Date();
        const fallbackTodayDate = fallbackToday.toISOString().split('T')[0];
        localStorage.setItem('pendingWorkoutGeneration', JSON.stringify({
          user_id: data.id,
          month_start_date: fallbackTodayDate,
          selected_days: onboardingData.selectedDays,
          duration_minutes: onboardingData.workoutDuration,
        }));

        setTimeout(() => {
          navigate('/');
        }, 1500);
      }
    },
    onError: (error) => {
      log.error('Failed to create/update user', error);
    },
  });

  const validateStep = (currentStep: number): boolean => {
    const newErrors: Record<string, string> = {};

    switch (currentStep) {
      case 0:
        if (!onboardingData.name || onboardingData.name.trim().length < 2) {
          newErrors.name = 'Name is required (at least 2 characters)';
        }
        if (!onboardingData.gender) {
          newErrors.gender = 'Please select your gender for accurate health metrics';
        }
        break;
      case 2:
        if (onboardingData.goals.length === 0) {
          newErrors.goals = 'Please select at least one goal';
        }
        break;
      case 3:
        if (onboardingData.selectedDays.length === 0) {
          newErrors.selectedDays = 'Please select at least one workout day';
        }
        break;
    }

    setErrors(newErrors);
    return Object.keys(newErrors).length === 0;
  };

  const handleNext = () => {
    if (!validateStep(step)) return;
    if (step < 5) {
      setStep(step + 1);
    } else {
      createUserMutation.mutate();
    }
  };

  const toggleArrayItem = (
    key: 'goals' | 'equipment' | 'workoutExperience' | 'activeInjuries' | 'healthConditions',
    item: string,
    exclusiveItem?: string
  ) => {
    const current = onboardingData[key] as string[];
    if (item === exclusiveItem) {
      setOnboardingData({ [key]: [item] });
      return;
    }
    const filtered = exclusiveItem ? current.filter((i) => i !== exclusiveItem) : current;
    const newItems = filtered.includes(item)
      ? filtered.filter((i) => i !== item)
      : [...filtered, item];
    setOnboardingData({ [key]: newItems.length > 0 ? newItems : exclusiveItem ? [exclusiveItem] : [] });
  };

  const toggleDay = (dayId: number) => {
    const current = onboardingData.selectedDays;
    const newDays = current.includes(dayId)
      ? current.filter((d) => d !== dayId)
      : [...current, dayId].sort((a, b) => a - b);
    setOnboardingData({
      selectedDays: newDays,
      daysPerWeek: newDays.length,
    });
  };

  const handleHeightCmChange = (strValue: string) => {
    const sanitized = strValue.replace(/[^0-9]/g, '');
    setHeightCmStr(sanitized);
    const value = parseInt(sanitized) || 0;
    setOnboardingData({ heightCm: value });
    const { feet, inches } = cmToFeetInches(value);
    setHeightFeet(feet);
    setHeightInches(inches);
    setHeightFeetStr(String(feet));
    setHeightInchesStr(String(inches));
  };

  const handleHeightFeetChange = (strValue: string) => {
    const sanitized = strValue.replace(/[^0-9]/g, '');
    setHeightFeetStr(sanitized);
    const value = parseInt(sanitized) || 0;
    setHeightFeet(value);
    setOnboardingData({ heightCm: feetInchesToCm(value, heightInches) });
    setHeightCmStr(String(feetInchesToCm(value, heightInches)));
  };

  const handleHeightInchesChange = (strValue: string) => {
    const sanitized = strValue.replace(/[^0-9]/g, '');
    setHeightInchesStr(sanitized);
    const value = parseInt(sanitized) || 0;
    setHeightInches(value);
    setOnboardingData({ heightCm: feetInchesToCm(heightFeet, value) });
    setHeightCmStr(String(feetInchesToCm(heightFeet, value)));
  };

  const handleWeightChange = (strValue: string, isMetric: boolean) => {
    const sanitized = strValue.replace(/[^0-9]/g, '');
    setWeightStr(sanitized);
    const value = parseInt(sanitized) || 0;
    setOnboardingData({ weightKg: isMetric ? value : lbsToKg(value) });
  };

  const handleTargetWeightChange = (strValue: string, isMetric: boolean) => {
    const sanitized = strValue.replace(/[^0-9]/g, '');
    setTargetWeightStr(sanitized);
    const value = parseInt(sanitized) || 0;
    setOnboardingData({ targetWeightKg: isMetric ? value || undefined : value ? lbsToKg(value) : undefined });
  };

  const handleToggleWeightUnit = () => {
    const newIsMetric = !useMetricWeight;
    setUseMetricWeight(newIsMetric);
    if (newIsMetric) {
      setWeightStr(String(onboardingData.weightKg));
      setTargetWeightStr(onboardingData.targetWeightKg ? String(onboardingData.targetWeightKg) : '');
    } else {
      setWeightStr(String(kgToLbs(onboardingData.weightKg)));
      setTargetWeightStr(onboardingData.targetWeightKg ? String(kgToLbs(onboardingData.targetWeightKg)) : '');
    }
  };

  const handleToggleHeightUnit = () => {
    const newIsMetric = !useMetricHeight;
    setUseMetricHeight(newIsMetric);
    if (newIsMetric) {
      setHeightCmStr(String(onboardingData.heightCm));
    } else {
      const { feet, inches } = cmToFeetInches(onboardingData.heightCm);
      setHeightFeetStr(String(feet));
      setHeightInchesStr(String(inches));
    }
  };

  // Loading screen
  if (isGenerating || createUserMutation.isPending) {
    return (
      <div className="min-h-screen bg-background flex items-center justify-center p-4 relative overflow-hidden">
        {/* Animated background */}
        <div className="absolute inset-0 overflow-hidden">
          <div className="absolute top-1/4 left-1/4 w-96 h-96 bg-primary/20 rounded-full blur-3xl animate-pulse" />
          <div className="absolute bottom-1/4 right-1/4 w-96 h-96 bg-secondary/20 rounded-full blur-3xl animate-pulse delay-1000" />
        </div>

        <GlassCard className="max-w-md w-full p-8 text-center relative z-10">
          <div className="w-20 h-20 bg-gradient-to-br from-primary to-secondary rounded-2xl flex items-center justify-center mx-auto mb-6 animate-pulse glow-primary">
            <Icons.Sparkles />
          </div>
          <h2 className="text-2xl font-bold text-text mb-2">Setting Up Your Plan</h2>
          <p className="text-text-secondary mb-6">{generationProgress || 'Creating your profile...'}</p>
          <ProgressBar current={60} total={100} variant="glow" />
        </GlassCard>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-background flex items-center justify-center p-4 relative overflow-hidden">
      {/* Animated background gradients */}
      <div className="absolute inset-0 overflow-hidden pointer-events-none">
        <div className="absolute top-0 left-1/4 w-[600px] h-[600px] bg-primary/10 rounded-full blur-3xl" />
        <div className="absolute bottom-0 right-1/4 w-[500px] h-[500px] bg-secondary/10 rounded-full blur-3xl" />
        <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-[800px] h-[800px] bg-accent/5 rounded-full blur-3xl" />
      </div>

      <div className="w-full max-w-lg relative z-10">
        {/* Step indicators */}
        <div className="flex justify-center gap-2 mb-6">
          {STEPS.map((s, i) => (
            <button
              key={i}
              onClick={() => i < step && setStep(i)}
              disabled={i > step}
              className={`
                relative flex items-center justify-center w-10 h-10 rounded-full
                transition-all duration-300
                ${i === step
                  ? 'bg-gradient-to-br from-primary to-primary-dark glow-primary scale-110'
                  : i < step
                  ? 'bg-accent/20 border border-accent/50'
                  : 'bg-white/5 border border-white/10'
                }
                ${i < step ? 'cursor-pointer hover:scale-105' : ''}
              `}
            >
              <s.Icon />
              {i < step && (
                <div className="absolute inset-0 flex items-center justify-center bg-accent rounded-full">
                  <svg className="w-5 h-5 text-white" fill="currentColor" viewBox="0 0 20 20">
                    <path fillRule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z" clipRule="evenodd" />
                  </svg>
                </div>
              )}
            </button>
          ))}
        </div>

        {/* Main card */}
        <GlassCard className="p-8 spring-in" variant="elevated">
          {/* Step 0: Personal Info */}
          {step === 0 && (
            <div className="space-y-6 fade-in-up">
              <div className="text-center mb-8">
                <div className="w-20 h-20 bg-gradient-to-br from-primary to-secondary rounded-2xl flex items-center justify-center mx-auto mb-4 glow-primary">
                  <Icons.Dumbbell />
                </div>
                <h1 className="text-3xl font-bold text-text text-glow-primary">Welcome!</h1>
                <p className="text-text-secondary mt-2">Let's personalize your fitness journey</p>
              </div>

              <GlassInput
                label="Your Name"
                placeholder="Enter your name"
                value={onboardingData.name}
                onChange={(e) => {
                  setOnboardingData({ name: e.target.value });
                  if (errors.name) setErrors((prev) => ({ ...prev, name: '' }));
                }}
                error={errors.name}
                required
              />

              <div>
                <label className="block text-sm font-medium text-text-secondary mb-3">
                  Gender <span className="text-coral">*</span>
                </label>
                <div className="grid grid-cols-2 gap-3">
                  {GENDERS.map((g) => (
                    <button
                      key={g.id}
                      onClick={() => {
                        setOnboardingData({ gender: g.id });
                        if (errors.gender) setErrors((prev) => ({ ...prev, gender: '' }));
                      }}
                      className={`
                        p-4 rounded-xl border transition-all duration-200
                        flex items-center justify-center gap-3
                        ${onboardingData.gender === g.id
                          ? 'border-primary bg-primary/20 text-primary shadow-[0_0_20px_rgba(6,182,212,0.3)]'
                          : errors.gender
                          ? 'border-coral/50 bg-coral/5 text-text-secondary'
                          : 'border-white/10 bg-white/5 text-text-secondary hover:border-white/20'
                        }
                      `}
                    >
                      <span className="text-2xl">{g.icon}</span>
                      <span className="font-medium">{g.label}</span>
                    </button>
                  ))}
                </div>
                {errors.gender && (
                  <p className="text-coral text-sm mt-2">{errors.gender}</p>
                )}
                <p className="text-xs text-text-muted mt-2">Required for accurate health metrics</p>
              </div>

              <GlassInput
                label="Age"
                type="number"
                value={onboardingData.age}
                onChange={(e) => setOnboardingData({ age: parseInt(e.target.value) || 0 })}
                min={13}
                max={100}
              />
            </div>
          )}

          {/* Step 1: Body Metrics */}
          {step === 1 && (
            <div className="space-y-6 fade-in-up">
              <div className="text-center mb-6">
                <h1 className="text-2xl font-bold text-text">Body Metrics</h1>
                <p className="text-text-secondary mt-1">Help us personalize your workouts</p>
              </div>

              {/* Height */}
              <div>
                <div className="flex justify-between items-center mb-2">
                  <label className="text-sm font-medium text-text-secondary">Height</label>
                  <button
                    onClick={handleToggleHeightUnit}
                    className="text-sm text-primary hover:text-primary-light transition-colors"
                  >
                    Switch to {useMetricHeight ? 'ft/in' : 'cm'}
                  </button>
                </div>
                {useMetricHeight ? (
                  <GlassInput
                    type="text"
                    inputMode="numeric"
                    pattern="[0-9]*"
                    value={heightCmStr}
                    onChange={(e) => handleHeightCmChange(e.target.value)}
                    placeholder="170"
                    suffix={<span className="text-text-muted">cm</span>}
                  />
                ) : (
                  <div className="flex gap-3">
                    <GlassInput
                      type="text"
                      inputMode="numeric"
                      pattern="[0-9]*"
                      value={heightFeetStr}
                      onChange={(e) => handleHeightFeetChange(e.target.value)}
                      placeholder="5"
                      suffix={<span className="text-text-muted">ft</span>}
                    />
                    <GlassInput
                      type="text"
                      inputMode="numeric"
                      pattern="[0-9]*"
                      value={heightInchesStr}
                      onChange={(e) => handleHeightInchesChange(e.target.value)}
                      placeholder="7"
                      suffix={<span className="text-text-muted">in</span>}
                    />
                  </div>
                )}
              </div>

              {/* Weight */}
              <div>
                <div className="flex justify-between items-center mb-2">
                  <label className="text-sm font-medium text-text-secondary">Current Weight</label>
                  <button
                    onClick={handleToggleWeightUnit}
                    className="text-sm text-primary hover:text-primary-light transition-colors"
                  >
                    Switch to {useMetricWeight ? 'lbs' : 'kg'}
                  </button>
                </div>
                <GlassInput
                  type="text"
                  inputMode="numeric"
                  pattern="[0-9]*"
                  value={weightStr}
                  onChange={(e) => handleWeightChange(e.target.value, useMetricWeight)}
                  placeholder={useMetricWeight ? '70' : '154'}
                  suffix={<span className="text-text-muted">{useMetricWeight ? 'kg' : 'lbs'}</span>}
                />
              </div>

              {/* Target Weight */}
              <GlassInput
                label="Target Weight (optional)"
                type="text"
                inputMode="numeric"
                pattern="[0-9]*"
                value={targetWeightStr}
                onChange={(e) => handleTargetWeightChange(e.target.value, useMetricWeight)}
                placeholder="Leave blank if none"
                suffix={<span className="text-text-muted">{useMetricWeight ? 'kg' : 'lbs'}</span>}
              />

              {/* Advanced Measurements */}
              <div className="border-t border-white/10 pt-4">
                <button
                  type="button"
                  onClick={() => setShowAdvancedMeasurements(!showAdvancedMeasurements)}
                  className="flex items-center justify-between w-full text-left group"
                >
                  <div>
                    <span className="text-sm font-medium text-text-secondary group-hover:text-text transition-colors">
                      Advanced Measurements
                    </span>
                    <span className="text-xs text-text-muted ml-2">(optional)</span>
                  </div>
                  <div className={`transition-transform duration-200 ${showAdvancedMeasurements ? 'rotate-180' : ''}`}>
                    <Icons.ChevronDown />
                  </div>
                </button>

                {showAdvancedMeasurements && (
                  <div className="mt-4 space-y-4 p-4 bg-white/5 rounded-xl border border-white/10 fade-in-up">
                    <div className="grid grid-cols-3 gap-3">
                      <GlassInput
                        label="Waist"
                        type="text"
                        inputMode="numeric"
                        value={waistStr}
                        onChange={(e) => {
                          const sanitized = e.target.value.replace(/[^0-9]/g, '');
                          setWaistStr(sanitized);
                          setOnboardingData({ waistCircumferenceCm: sanitized ? parseInt(sanitized) : undefined });
                        }}
                        placeholder="cm"
                      />
                      <GlassInput
                        label="Hip"
                        type="text"
                        inputMode="numeric"
                        value={hipStr}
                        onChange={(e) => {
                          const sanitized = e.target.value.replace(/[^0-9]/g, '');
                          setHipStr(sanitized);
                          setOnboardingData({ hipCircumferenceCm: sanitized ? parseInt(sanitized) : undefined });
                        }}
                        placeholder="cm"
                      />
                      <GlassInput
                        label="Neck"
                        type="text"
                        inputMode="numeric"
                        value={neckStr}
                        onChange={(e) => {
                          const sanitized = e.target.value.replace(/[^0-9]/g, '');
                          setNeckStr(sanitized);
                          setOnboardingData({ neckCircumferenceCm: sanitized ? parseInt(sanitized) : undefined });
                        }}
                        placeholder="cm"
                      />
                    </div>
                    <GlassInput
                      label="Body Fat %"
                      type="text"
                      inputMode="decimal"
                      value={bodyFatStr}
                      onChange={(e) => {
                        const sanitized = e.target.value.replace(/[^0-9.]/g, '');
                        setBodyFatStr(sanitized);
                        setOnboardingData({ bodyFatPercent: sanitized ? parseFloat(sanitized) : undefined });
                      }}
                      placeholder="e.g., 18.5"
                      hint="If known"
                    />
                    <GlassInput
                      label="Resting Heart Rate"
                      type="text"
                      inputMode="numeric"
                      value={restingHRStr}
                      onChange={(e) => {
                        const sanitized = e.target.value.replace(/[^0-9]/g, '');
                        setRestingHRStr(sanitized);
                        setOnboardingData({ restingHeartRate: sanitized ? parseInt(sanitized) : undefined });
                      }}
                      placeholder="e.g., 65"
                      suffix={<span className="text-text-muted text-xs">bpm</span>}
                    />
                    <div>
                      <label className="block text-sm font-medium text-text-secondary mb-2">Blood Pressure</label>
                      <div className="flex items-center gap-2">
                        <GlassInput
                          type="text"
                          inputMode="numeric"
                          value={bpSystolicStr}
                          onChange={(e) => {
                            const sanitized = e.target.value.replace(/[^0-9]/g, '');
                            setBpSystolicStr(sanitized);
                            setOnboardingData({ bloodPressureSystolic: sanitized ? parseInt(sanitized) : undefined });
                          }}
                          placeholder="120"
                          className="flex-1"
                        />
                        <span className="text-text-muted">/</span>
                        <GlassInput
                          type="text"
                          inputMode="numeric"
                          value={bpDiastolicStr}
                          onChange={(e) => {
                            const sanitized = e.target.value.replace(/[^0-9]/g, '');
                            setBpDiastolicStr(sanitized);
                            setOnboardingData({ bloodPressureDiastolic: sanitized ? parseInt(sanitized) : undefined });
                          }}
                          placeholder="80"
                          className="flex-1"
                        />
                        <span className="text-text-muted text-xs">mmHg</span>
                      </div>
                    </div>
                  </div>
                )}
              </div>
            </div>
          )}

          {/* Step 2: Fitness Background */}
          {step === 2 && (
            <div className="space-y-6 fade-in-up">
              <div className="text-center mb-6">
                <h1 className="text-2xl font-bold text-text">Fitness Background</h1>
                <p className="text-text-secondary mt-1">Tell us about your fitness journey</p>
              </div>

              <div>
                <label className="block text-sm font-medium text-text-secondary mb-3">Fitness Level</label>
                <div className="space-y-2">
                  {FITNESS_LEVELS.map((level) => (
                    <button
                      key={level.id}
                      onClick={() => setOnboardingData({ fitnessLevel: level.id })}
                      className={`
                        w-full p-4 text-left rounded-xl border transition-all duration-200
                        ${onboardingData.fitnessLevel === level.id
                          ? 'border-primary bg-primary/20 shadow-[0_0_20px_rgba(6,182,212,0.2)]'
                          : 'border-white/10 bg-white/5 hover:border-white/20'
                        }
                      `}
                    >
                      <div className="flex items-center gap-3">
                        <span className="text-2xl">{level.icon}</span>
                        <div>
                          <div className="font-semibold text-text">{level.label}</div>
                          <div className="text-sm text-text-secondary">{level.desc}</div>
                        </div>
                      </div>
                    </button>
                  ))}
                </div>
              </div>

              <div>
                <label className="block text-sm font-medium text-text-secondary mb-3">
                  Goals <span className="text-coral">*</span>
                  <span className="text-text-muted font-normal ml-1">(select all that apply)</span>
                </label>
                <div className="flex flex-wrap gap-2">
                  {GOALS.map((goal) => (
                    <SelectionChip
                      key={goal}
                      selected={onboardingData.goals.includes(goal)}
                      onClick={() => {
                        toggleArrayItem('goals', goal);
                        if (errors.goals) setErrors((prev) => ({ ...prev, goals: '' }));
                      }}
                      variant="primary"
                    >
                      {goal}
                    </SelectionChip>
                  ))}
                </div>
                {errors.goals && (
                  <p className="text-coral text-sm mt-2">{errors.goals}</p>
                )}
              </div>

              <div>
                <label className="block text-sm font-medium text-text-secondary mb-3">Previous Experience</label>
                <div className="flex flex-wrap gap-2">
                  {WORKOUT_EXPERIENCE.map((exp) => (
                    <SelectionChip
                      key={exp}
                      selected={onboardingData.workoutExperience.includes(exp)}
                      onClick={() => toggleArrayItem('workoutExperience', exp, 'None')}
                      variant="secondary"
                    >
                      {exp}
                    </SelectionChip>
                  ))}
                </div>
              </div>
            </div>
          )}

          {/* Step 3: Schedule */}
          {step === 3 && (
            <div className="space-y-6 fade-in-up">
              <div className="text-center mb-6">
                <h1 className="text-2xl font-bold text-text">Your Schedule</h1>
                <p className="text-text-secondary mt-1">When do you want to work out?</p>
              </div>

              <div>
                <label className="block text-sm font-medium text-text-secondary mb-3">
                  Select Workout Days <span className="text-coral">*</span>
                  <span className="text-text-muted font-normal ml-1">({onboardingData.selectedDays.length} days/week)</span>
                </label>
                <div className="grid grid-cols-7 gap-2">
                  {DAYS_OF_WEEK.map((day) => (
                    <button
                      key={day.id}
                      onClick={() => {
                        toggleDay(day.id);
                        if (errors.selectedDays) setErrors((prev) => ({ ...prev, selectedDays: '' }));
                      }}
                      title={day.label}
                      className={`
                        aspect-square flex flex-col items-center justify-center rounded-xl border
                        transition-all duration-200
                        ${onboardingData.selectedDays.includes(day.id)
                          ? 'border-primary bg-gradient-to-br from-primary to-primary-dark text-white shadow-[0_0_15px_rgba(6,182,212,0.4)]'
                          : errors.selectedDays
                          ? 'border-coral/50 bg-coral/5 text-text-secondary'
                          : 'border-white/10 bg-white/5 text-text-secondary hover:border-white/20'
                        }
                      `}
                    >
                      <span className="text-lg font-bold">{day.short}</span>
                    </button>
                  ))}
                </div>
                {errors.selectedDays && (
                  <p className="text-coral text-sm mt-2">{errors.selectedDays}</p>
                )}
                <p className="text-xs text-text-muted mt-2">M=Monday, T=Tuesday, W=Wednesday, T=Thursday, F=Friday, S=Saturday, S=Sunday</p>
              </div>

              <div>
                <label className="block text-sm font-medium text-text-secondary mb-3">Preferred Time</label>
                <div className="grid grid-cols-3 gap-3">
                  {PREFERRED_TIMES.map((time) => (
                    <button
                      key={time.id}
                      onClick={() => setOnboardingData({ preferredTime: time.id })}
                      className={`
                        p-4 rounded-xl border transition-all duration-200 text-center
                        ${onboardingData.preferredTime === time.id
                          ? 'border-primary bg-primary/20 shadow-[0_0_15px_rgba(6,182,212,0.3)]'
                          : 'border-white/10 bg-white/5 hover:border-white/20'
                        }
                      `}
                    >
                      <div className={`mx-auto mb-2 ${onboardingData.preferredTime === time.id ? 'text-primary' : 'text-text-secondary'}`}>
                        <time.Icon />
                      </div>
                      <div className="text-sm font-medium text-text">{time.label}</div>
                    </button>
                  ))}
                </div>
              </div>

              <div>
                <label className="block text-sm font-medium text-text-secondary mb-3">Workout Duration</label>
                <div className="grid grid-cols-5 gap-2">
                  {WORKOUT_DURATIONS.map((duration) => (
                    <button
                      key={duration}
                      onClick={() => setOnboardingData({ workoutDuration: duration })}
                      className={`
                        p-3 rounded-xl border transition-all duration-200 text-center
                        ${onboardingData.workoutDuration === duration
                          ? 'border-primary bg-primary/20 shadow-[0_0_15px_rgba(6,182,212,0.3)]'
                          : 'border-white/10 bg-white/5 hover:border-white/20'
                        }
                      `}
                    >
                      <div className="font-bold text-text">{duration}</div>
                      <div className="text-xs text-text-muted">min</div>
                    </button>
                  ))}
                </div>
              </div>
            </div>
          )}

          {/* Step 4: Workout Preferences */}
          {step === 4 && (
            <div className="space-y-6 fade-in-up">
              <div className="text-center mb-6">
                <h1 className="text-2xl font-bold text-text">Workout Preferences</h1>
                <p className="text-text-secondary mt-1">Customize your training style</p>
              </div>

              <div>
                <label className="block text-sm font-medium text-text-secondary mb-3">Training Split</label>
                <div className="space-y-2">
                  {TRAINING_SPLITS.map((split) => (
                    <button
                      key={split.id}
                      onClick={() => setOnboardingData({ trainingSplit: split.id })}
                      className={`
                        w-full p-4 text-left rounded-xl border transition-all duration-200
                        ${onboardingData.trainingSplit === split.id
                          ? 'border-primary bg-primary/20 shadow-[0_0_15px_rgba(6,182,212,0.2)]'
                          : 'border-white/10 bg-white/5 hover:border-white/20'
                        }
                      `}
                    >
                      <div className="font-semibold text-text">{split.label}</div>
                      <div className="text-sm text-text-secondary">{split.desc}</div>
                    </button>
                  ))}
                </div>
              </div>

              <div>
                <label className="block text-sm font-medium text-text-secondary mb-3">Intensity Level</label>
                <div className="grid grid-cols-3 gap-2">
                  {INTENSITY_LEVELS.map((intensity) => (
                    <button
                      key={intensity.id}
                      onClick={() => setOnboardingData({ intensityPreference: intensity.id })}
                      className={`
                        p-3 rounded-xl border transition-all duration-200 text-center
                        ${onboardingData.intensityPreference === intensity.id
                          ? 'border-primary bg-primary/20 shadow-[0_0_15px_rgba(6,182,212,0.3)]'
                          : 'border-white/10 bg-white/5 hover:border-white/20'
                        }
                      `}
                    >
                      <div className="font-semibold text-sm text-text">{intensity.label}</div>
                      <div className="text-xs text-text-muted mt-1">{intensity.desc}</div>
                    </button>
                  ))}
                </div>
              </div>

              <div>
                <label className="block text-sm font-medium text-text-secondary mb-3">Equipment Available</label>
                <div className="flex flex-wrap gap-2">
                  {EQUIPMENT.map((equip) => (
                    <SelectionChip
                      key={equip}
                      selected={onboardingData.equipment.includes(equip)}
                      onClick={() => toggleArrayItem('equipment', equip)}
                      variant="secondary"
                    >
                      {equip}
                    </SelectionChip>
                  ))}
                </div>
              </div>

              <div>
                <label className="block text-sm font-medium text-text-secondary mb-3">Workout Variety</label>
                <div className="grid grid-cols-2 gap-3">
                  {WORKOUT_VARIETY.map((variety) => (
                    <button
                      key={variety.id}
                      onClick={() => setOnboardingData({ workoutVariety: variety.id })}
                      className={`
                        p-4 rounded-xl border transition-all duration-200 text-left
                        ${onboardingData.workoutVariety === variety.id
                          ? 'border-primary bg-primary/20 shadow-[0_0_15px_rgba(6,182,212,0.3)]'
                          : 'border-white/10 bg-white/5 hover:border-white/20'
                        }
                      `}
                    >
                      <div className="font-semibold text-sm text-text">{variety.label}</div>
                      <div className="text-xs text-text-muted mt-1">{variety.desc}</div>
                    </button>
                  ))}
                </div>
              </div>
            </div>
          )}

          {/* Step 5: Health & Limitations */}
          {step === 5 && (
            <div className="space-y-6 fade-in-up">
              <div className="text-center mb-6">
                <h1 className="text-2xl font-bold text-text">Health & Limitations</h1>
                <p className="text-text-secondary mt-1">Help us keep your workouts safe</p>
              </div>

              <div>
                <label className="block text-sm font-medium text-text-secondary mb-3">Any Injuries or Pain?</label>
                <div className="flex flex-wrap gap-2">
                  {INJURY_OPTIONS.map((injury) => (
                    <SelectionChip
                      key={injury}
                      selected={onboardingData.activeInjuries.includes(injury)}
                      onClick={() => toggleArrayItem('activeInjuries', injury, 'None')}
                      variant="warning"
                    >
                      {injury}
                    </SelectionChip>
                  ))}
                </div>
              </div>

              <div>
                <label className="block text-sm font-medium text-text-secondary mb-3">Health Conditions</label>
                <div className="flex flex-wrap gap-2">
                  {HEALTH_CONDITIONS.map((condition) => (
                    <SelectionChip
                      key={condition}
                      selected={onboardingData.healthConditions.includes(condition)}
                      onClick={() => toggleArrayItem('healthConditions', condition, 'None')}
                      variant="warning"
                    >
                      {condition}
                    </SelectionChip>
                  ))}
                </div>
              </div>

              <div>
                <label className="block text-sm font-medium text-text-secondary mb-3">Daily Activity Level</label>
                <div className="space-y-2">
                  {ACTIVITY_LEVELS.map((level) => (
                    <button
                      key={level.id}
                      onClick={() => setOnboardingData({ activityLevel: level.id })}
                      className={`
                        w-full p-4 text-left rounded-xl border transition-all duration-200
                        ${onboardingData.activityLevel === level.id
                          ? 'border-primary bg-primary/20 shadow-[0_0_15px_rgba(6,182,212,0.2)]'
                          : 'border-white/10 bg-white/5 hover:border-white/20'
                        }
                      `}
                    >
                      <div className="font-semibold text-text">{level.label}</div>
                      <div className="text-sm text-text-secondary">{level.desc}</div>
                    </button>
                  ))}
                </div>
              </div>
            </div>
          )}

          {/* Navigation */}
          <div className="flex gap-4 mt-8 pt-6 border-t border-white/10">
            {step > 0 && (
              <GlassButton
                variant="secondary"
                onClick={() => setStep(step - 1)}
                fullWidth
              >
                Back
              </GlassButton>
            )}
            <GlassButton
              onClick={handleNext}
              loading={createUserMutation.isPending || isGenerating}
              fullWidth
            >
              {step === 5 ? 'Create My Plan' : 'Continue'}
            </GlassButton>
          </div>
        </GlassCard>
      </div>
    </div>
  );
}
