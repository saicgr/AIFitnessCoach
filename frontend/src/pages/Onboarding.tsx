import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { useMutation } from '@tanstack/react-query';
import { useAppStore } from '../store';
import { createUser, updateUser, generateWorkout } from '../api/client';
import { createLogger } from '../utils/logger';

const log = createLogger('onboarding');

// Constants for options
const GENDERS = [
  { id: 'male', label: 'Male' },
  { id: 'female', label: 'Female' },
  { id: 'other', label: 'Other' },
  { id: 'prefer_not_to_say', label: 'Prefer not to say' },
] as const;

const FITNESS_LEVELS = [
  { id: 'beginner', label: 'Beginner', desc: 'New to fitness or returning after a break' },
  { id: 'intermediate', label: 'Intermediate', desc: 'Regular exercise for 6+ months' },
  { id: 'advanced', label: 'Advanced', desc: 'Consistent training for 2+ years' },
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
  { id: 'morning', label: 'Morning', icon: '🌅' },
  { id: 'afternoon', label: 'Afternoon', icon: '☀️' },
  { id: 'evening', label: 'Evening', icon: '🌙' },
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

  // String state for number inputs (to handle leading zeros properly)
  const [heightCmStr, setHeightCmStr] = useState(String(onboardingData.heightCm));
  const [heightFeetStr, setHeightFeetStr] = useState('5');
  const [heightInchesStr, setHeightInchesStr] = useState('7');
  const [weightStr, setWeightStr] = useState(String(onboardingData.weightKg));
  const [targetWeightStr, setTargetWeightStr] = useState(
    onboardingData.targetWeightKg ? String(onboardingData.targetWeightKg) : ''
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
      });

      if (user) {
        return updateUser(user.id, {
          fitness_level: onboardingData.fitnessLevel,
          goals: JSON.stringify(onboardingData.goals),
          equipment: JSON.stringify(onboardingData.equipment),
          preferences,
          active_injuries: JSON.stringify(onboardingData.activeInjuries),
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

      // Generate only the first workout quickly, then navigate
      setIsGenerating(true);
      setGenerationProgress('Creating your first workout...');

      try {
        const today = new Date();
        // Use TODAY as start date, not the 1st of the month
        const todayDate = today.toISOString().split('T')[0];

        log.info(`Generating first workout for user ${data.id}`, {
          selectedDays: onboardingData.selectedDays,
          duration: onboardingData.workoutDuration,
        });

        // Generate just ONE workout for today or the next workout day
        await generateWorkout({
          user_id: data.id,
          duration_minutes: onboardingData.workoutDuration,
          fitness_level: onboardingData.fitnessLevel,
          goals: onboardingData.goals,
          equipment: onboardingData.equipment,
        });

        log.info('First workout generated');
        setGenerationProgress('Your first workout is ready! Loading your schedule...');

        // Store pending generation params in localStorage for Home.tsx to pick up
        localStorage.setItem('pendingWorkoutGeneration', JSON.stringify({
          user_id: data.id,
          month_start_date: todayDate,  // Start from today, not 1st of month
          selected_days: onboardingData.selectedDays,
          duration_minutes: onboardingData.workoutDuration,
        }));

        setTimeout(() => {
          navigate('/');
        }, 1000);
      } catch (error) {
        log.error('Failed to generate first workout', error);
        setGenerationProgress('Could not generate workout. Redirecting...');

        // Still store pending generation so Home can retry
        // Use TODAY as start date, not the 1st of the month
        const fallbackToday = new Date();
        const fallbackTodayDate = fallbackToday.toISOString().split('T')[0];
        localStorage.setItem('pendingWorkoutGeneration', JSON.stringify({
          user_id: data.id,
          month_start_date: fallbackTodayDate,  // Start from today, not 1st of month
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

  const handleNext = () => {
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

    // Handle exclusive items like "None"
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
    // Allow only digits
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
    if (isMetric) {
      setOnboardingData({ weightKg: value });
    } else {
      setOnboardingData({ weightKg: lbsToKg(value) });
    }
  };

  const handleTargetWeightChange = (strValue: string, isMetric: boolean) => {
    const sanitized = strValue.replace(/[^0-9]/g, '');
    setTargetWeightStr(sanitized);
    const value = parseInt(sanitized) || 0;
    if (isMetric) {
      setOnboardingData({ targetWeightKg: value || undefined });
    } else {
      setOnboardingData({ targetWeightKg: value ? lbsToKg(value) : undefined });
    }
  };

  // Sync weight display string when toggling units
  const handleToggleWeightUnit = () => {
    const newIsMetric = !useMetricWeight;
    setUseMetricWeight(newIsMetric);
    // Update display string based on new unit
    if (newIsMetric) {
      setWeightStr(String(onboardingData.weightKg));
      setTargetWeightStr(onboardingData.targetWeightKg ? String(onboardingData.targetWeightKg) : '');
    } else {
      setWeightStr(String(kgToLbs(onboardingData.weightKg)));
      setTargetWeightStr(onboardingData.targetWeightKg ? String(kgToLbs(onboardingData.targetWeightKg)) : '');
    }
  };

  // Sync height display string when toggling units
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

  // Loading screen during workout generation
  if (isGenerating || createUserMutation.isPending) {
    return (
      <div className="min-h-screen bg-gradient-to-br from-primary to-primary-dark flex items-center justify-center p-4">
        <div className="bg-white rounded-2xl shadow-xl max-w-md w-full p-8 text-center">
          <div className="w-20 h-20 bg-primary/10 text-primary rounded-full flex items-center justify-center text-3xl mx-auto mb-6 animate-pulse">
            AI
          </div>
          <h2 className="text-xl font-bold text-gray-900 mb-2">Setting Up Your Plan</h2>
          <p className="text-gray-600 mb-6">{generationProgress || 'Creating your profile...'}</p>
          <div className="w-full bg-gray-200 rounded-full h-2">
            <div className="bg-primary h-2 rounded-full animate-pulse" style={{ width: '60%' }}></div>
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gradient-to-br from-primary to-primary-dark flex items-center justify-center p-4">
      <div className="bg-white rounded-2xl shadow-xl max-w-lg w-full p-8 max-h-[90vh] overflow-y-auto">
        {/* Progress */}
        <div className="flex gap-2 mb-8">
          {[0, 1, 2, 3, 4, 5].map((i) => (
            <div
              key={i}
              className={`h-2 flex-1 rounded-full transition-colors ${
                i <= step ? 'bg-primary' : 'bg-gray-200'
              }`}
            />
          ))}
        </div>

        {/* Screen 1: Personal Info (Welcome + Name + Gender + Age) */}
        {step === 0 && (
          <div className="space-y-6">
            <div className="text-center mb-6">
              <div className="w-16 h-16 bg-primary/10 text-primary rounded-full flex items-center justify-center text-2xl mx-auto mb-4">
                AI
              </div>
              <h1 className="text-2xl font-bold text-gray-900">Welcome to AI Fitness Coach!</h1>
              <p className="text-gray-600 mt-2">Let's get to know you better</p>
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700 mb-2">Your Name</label>
              <input
                type="text"
                value={onboardingData.name}
                onChange={(e) => setOnboardingData({ name: e.target.value })}
                placeholder="Enter your name"
                className="w-full p-3 border-2 border-gray-200 rounded-lg focus:border-primary focus:outline-none"
              />
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700 mb-2">Gender</label>
              <div className="grid grid-cols-2 gap-2">
                {GENDERS.map((g) => (
                  <button
                    key={g.id}
                    onClick={() => setOnboardingData({ gender: g.id })}
                    className={`p-3 rounded-lg border-2 transition-colors ${
                      onboardingData.gender === g.id
                        ? 'border-primary bg-primary/5'
                        : 'border-gray-200 hover:border-gray-300'
                    }`}
                  >
                    {g.label}
                  </button>
                ))}
              </div>
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700 mb-2">Age</label>
              <input
                type="number"
                value={onboardingData.age}
                onChange={(e) => setOnboardingData({ age: parseInt(e.target.value) || 0 })}
                min={13}
                max={100}
                className="w-full p-3 border-2 border-gray-200 rounded-lg focus:border-primary focus:outline-none"
              />
            </div>
          </div>
        )}

        {/* Screen 2: Body Metrics (Height + Weight + Target Weight) */}
        {step === 1 && (
          <div className="space-y-6">
            <div>
              <h1 className="text-2xl font-bold text-gray-900">Body Metrics</h1>
              <p className="text-gray-600 mt-2">Help us personalize your workouts</p>
            </div>

            {/* Height */}
            <div>
              <div className="flex justify-between items-center mb-2">
                <label className="text-sm font-medium text-gray-700">Height</label>
                <button
                  onClick={handleToggleHeightUnit}
                  className="text-sm text-primary hover:text-primary-dark"
                >
                  Switch to {useMetricHeight ? 'ft/in' : 'cm'}
                </button>
              </div>
              {useMetricHeight ? (
                <div className="flex items-center gap-2">
                  <input
                    type="text"
                    inputMode="numeric"
                    pattern="[0-9]*"
                    value={heightCmStr}
                    onChange={(e) => handleHeightCmChange(e.target.value)}
                    placeholder="170"
                    className="flex-1 p-3 border-2 border-gray-200 rounded-lg focus:border-primary focus:outline-none"
                  />
                  <span className="text-gray-600 w-12">cm</span>
                </div>
              ) : (
                <div className="flex items-center gap-2">
                  <input
                    type="text"
                    inputMode="numeric"
                    pattern="[0-9]*"
                    value={heightFeetStr}
                    onChange={(e) => handleHeightFeetChange(e.target.value)}
                    placeholder="5"
                    className="w-20 p-3 border-2 border-gray-200 rounded-lg focus:border-primary focus:outline-none"
                  />
                  <span className="text-gray-600">ft</span>
                  <input
                    type="text"
                    inputMode="numeric"
                    pattern="[0-9]*"
                    value={heightInchesStr}
                    onChange={(e) => handleHeightInchesChange(e.target.value)}
                    placeholder="7"
                    className="w-20 p-3 border-2 border-gray-200 rounded-lg focus:border-primary focus:outline-none"
                  />
                  <span className="text-gray-600">in</span>
                </div>
              )}
            </div>

            {/* Weight */}
            <div>
              <div className="flex justify-between items-center mb-2">
                <label className="text-sm font-medium text-gray-700">Current Weight</label>
                <button
                  onClick={handleToggleWeightUnit}
                  className="text-sm text-primary hover:text-primary-dark"
                >
                  Switch to {useMetricWeight ? 'lbs' : 'kg'}
                </button>
              </div>
              <div className="flex items-center gap-2">
                <input
                  type="text"
                  inputMode="numeric"
                  pattern="[0-9]*"
                  value={weightStr}
                  onChange={(e) => handleWeightChange(e.target.value, useMetricWeight)}
                  placeholder={useMetricWeight ? '70' : '154'}
                  className="flex-1 p-3 border-2 border-gray-200 rounded-lg focus:border-primary focus:outline-none"
                />
                <span className="text-gray-600 w-12">{useMetricWeight ? 'kg' : 'lbs'}</span>
              </div>
            </div>

            {/* Target Weight (Optional) */}
            <div>
              <label className="text-sm font-medium text-gray-700 mb-2 block">
                Target Weight <span className="text-gray-400">(optional)</span>
              </label>
              <div className="flex items-center gap-2">
                <input
                  type="text"
                  inputMode="numeric"
                  pattern="[0-9]*"
                  value={targetWeightStr}
                  onChange={(e) => handleTargetWeightChange(e.target.value, useMetricWeight)}
                  placeholder="Leave blank if none"
                  className="flex-1 p-3 border-2 border-gray-200 rounded-lg focus:border-primary focus:outline-none"
                />
                <span className="text-gray-600 w-12">{useMetricWeight ? 'kg' : 'lbs'}</span>
              </div>
            </div>
          </div>
        )}

        {/* Screen 3: Fitness Background (Level + Goals + Experience) */}
        {step === 2 && (
          <div className="space-y-6">
            <div>
              <h1 className="text-2xl font-bold text-gray-900">Fitness Background</h1>
              <p className="text-gray-600 mt-2">Tell us about your fitness journey</p>
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700 mb-2">Fitness Level</label>
              <div className="space-y-2">
                {FITNESS_LEVELS.map((level) => (
                  <button
                    key={level.id}
                    onClick={() => setOnboardingData({ fitnessLevel: level.id })}
                    className={`w-full p-3 text-left rounded-lg border-2 transition-colors ${
                      onboardingData.fitnessLevel === level.id
                        ? 'border-primary bg-primary/5'
                        : 'border-gray-200 hover:border-gray-300'
                    }`}
                  >
                    <div className="font-semibold text-gray-900">{level.label}</div>
                    <div className="text-sm text-gray-600">{level.desc}</div>
                  </button>
                ))}
              </div>
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700 mb-2">Goals (select all that apply)</label>
              <div className="flex flex-wrap gap-2">
                {GOALS.map((goal) => (
                  <button
                    key={goal}
                    onClick={() => toggleArrayItem('goals', goal)}
                    className={`px-3 py-2 rounded-full border-2 text-sm transition-colors ${
                      onboardingData.goals.includes(goal)
                        ? 'border-primary bg-primary text-white'
                        : 'border-gray-200 hover:border-gray-300'
                    }`}
                  >
                    {goal}
                  </button>
                ))}
              </div>
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700 mb-2">Previous Experience</label>
              <div className="flex flex-wrap gap-2">
                {WORKOUT_EXPERIENCE.map((exp) => (
                  <button
                    key={exp}
                    onClick={() => toggleArrayItem('workoutExperience', exp, 'None')}
                    className={`px-3 py-2 rounded-full border-2 text-sm transition-colors ${
                      onboardingData.workoutExperience.includes(exp)
                        ? 'border-secondary bg-secondary text-white'
                        : 'border-gray-200 hover:border-gray-300'
                    }`}
                  >
                    {exp}
                  </button>
                ))}
              </div>
            </div>
          </div>
        )}

        {/* Screen 4: Schedule (Days + Time + Duration) */}
        {step === 3 && (
          <div className="space-y-6">
            <div>
              <h1 className="text-2xl font-bold text-gray-900">Your Schedule</h1>
              <p className="text-gray-600 mt-2">When do you want to work out?</p>
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700 mb-2">
                Select Workout Days ({onboardingData.selectedDays.length} days/week)
              </label>
              <div className="grid grid-cols-7 gap-2">
                {DAYS_OF_WEEK.map((day) => (
                  <button
                    key={day.id}
                    onClick={() => toggleDay(day.id)}
                    title={day.label}
                    className={`aspect-square flex flex-col items-center justify-center rounded-lg border-2 transition-colors ${
                      onboardingData.selectedDays.includes(day.id)
                        ? 'border-primary bg-primary text-white'
                        : 'border-gray-200 hover:border-gray-300'
                    }`}
                  >
                    <span className="text-lg font-bold">{day.short}</span>
                  </button>
                ))}
              </div>
              <p className="text-xs text-gray-500 mt-1">M=Monday, T=Tuesday, W=Wednesday, T=Thursday, F=Friday, S=Saturday, S=Sunday</p>
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700 mb-2">Preferred Time</label>
              <div className="grid grid-cols-3 gap-2">
                {PREFERRED_TIMES.map((time) => (
                  <button
                    key={time.id}
                    onClick={() => setOnboardingData({ preferredTime: time.id })}
                    className={`p-3 rounded-lg border-2 transition-colors text-center ${
                      onboardingData.preferredTime === time.id
                        ? 'border-primary bg-primary/5'
                        : 'border-gray-200 hover:border-gray-300'
                    }`}
                  >
                    <div className="text-xl mb-1">{time.icon}</div>
                    <div className="text-sm font-medium">{time.label}</div>
                  </button>
                ))}
              </div>
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700 mb-2">Workout Duration</label>
              <div className="grid grid-cols-5 gap-2">
                {WORKOUT_DURATIONS.map((duration) => (
                  <button
                    key={duration}
                    onClick={() => setOnboardingData({ workoutDuration: duration })}
                    className={`p-3 rounded-lg border-2 transition-colors text-center ${
                      onboardingData.workoutDuration === duration
                        ? 'border-primary bg-primary/5'
                        : 'border-gray-200 hover:border-gray-300'
                    }`}
                  >
                    <div className="font-bold">{duration}</div>
                    <div className="text-xs text-gray-500">min</div>
                  </button>
                ))}
              </div>
            </div>
          </div>
        )}

        {/* Screen 5: Workout Preferences (Split + Intensity + Equipment + Variety) */}
        {step === 4 && (
          <div className="space-y-6">
            <div>
              <h1 className="text-2xl font-bold text-gray-900">Workout Preferences</h1>
              <p className="text-gray-600 mt-2">Customize your training style</p>
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700 mb-2">Training Split</label>
              <div className="space-y-2">
                {TRAINING_SPLITS.map((split) => (
                  <button
                    key={split.id}
                    onClick={() => setOnboardingData({ trainingSplit: split.id })}
                    className={`w-full p-3 text-left rounded-lg border-2 transition-colors ${
                      onboardingData.trainingSplit === split.id
                        ? 'border-primary bg-primary/5'
                        : 'border-gray-200 hover:border-gray-300'
                    }`}
                  >
                    <div className="font-semibold text-gray-900">{split.label}</div>
                    <div className="text-sm text-gray-600">{split.desc}</div>
                  </button>
                ))}
              </div>
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700 mb-2">Intensity Level</label>
              <div className="grid grid-cols-3 gap-2">
                {INTENSITY_LEVELS.map((intensity) => (
                  <button
                    key={intensity.id}
                    onClick={() => setOnboardingData({ intensityPreference: intensity.id })}
                    className={`p-3 rounded-lg border-2 transition-colors text-center ${
                      onboardingData.intensityPreference === intensity.id
                        ? 'border-primary bg-primary/5'
                        : 'border-gray-200 hover:border-gray-300'
                    }`}
                  >
                    <div className="font-semibold text-sm">{intensity.label}</div>
                    <div className="text-xs text-gray-500">{intensity.desc}</div>
                  </button>
                ))}
              </div>
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700 mb-2">Equipment Available</label>
              <div className="flex flex-wrap gap-2">
                {EQUIPMENT.map((equip) => (
                  <button
                    key={equip}
                    onClick={() => toggleArrayItem('equipment', equip)}
                    className={`px-3 py-2 rounded-full border-2 text-sm transition-colors ${
                      onboardingData.equipment.includes(equip)
                        ? 'border-secondary bg-secondary text-white'
                        : 'border-gray-200 hover:border-gray-300'
                    }`}
                  >
                    {equip}
                  </button>
                ))}
              </div>
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700 mb-2">Workout Variety</label>
              <div className="grid grid-cols-2 gap-2">
                {WORKOUT_VARIETY.map((variety) => (
                  <button
                    key={variety.id}
                    onClick={() => setOnboardingData({ workoutVariety: variety.id })}
                    className={`p-3 rounded-lg border-2 transition-colors text-left ${
                      onboardingData.workoutVariety === variety.id
                        ? 'border-primary bg-primary/5'
                        : 'border-gray-200 hover:border-gray-300'
                    }`}
                  >
                    <div className="font-semibold text-sm">{variety.label}</div>
                    <div className="text-xs text-gray-500">{variety.desc}</div>
                  </button>
                ))}
              </div>
            </div>
          </div>
        )}

        {/* Screen 6: Health & Limitations (Injuries + Conditions + Activity Level) */}
        {step === 5 && (
          <div className="space-y-6">
            <div>
              <h1 className="text-2xl font-bold text-gray-900">Health & Limitations</h1>
              <p className="text-gray-600 mt-2">Help us keep your workouts safe</p>
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700 mb-2">Any Injuries or Pain?</label>
              <div className="flex flex-wrap gap-2">
                {INJURY_OPTIONS.map((injury) => (
                  <button
                    key={injury}
                    onClick={() => toggleArrayItem('activeInjuries', injury, 'None')}
                    className={`px-3 py-2 rounded-full border-2 text-sm transition-colors ${
                      onboardingData.activeInjuries.includes(injury)
                        ? 'border-warning bg-warning/10 text-warning-dark'
                        : 'border-gray-200 hover:border-gray-300'
                    }`}
                  >
                    {injury}
                  </button>
                ))}
              </div>
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700 mb-2">Health Conditions</label>
              <div className="flex flex-wrap gap-2">
                {HEALTH_CONDITIONS.map((condition) => (
                  <button
                    key={condition}
                    onClick={() => toggleArrayItem('healthConditions', condition, 'None')}
                    className={`px-3 py-2 rounded-full border-2 text-sm transition-colors ${
                      onboardingData.healthConditions.includes(condition)
                        ? 'border-warning bg-warning/10 text-warning-dark'
                        : 'border-gray-200 hover:border-gray-300'
                    }`}
                  >
                    {condition}
                  </button>
                ))}
              </div>
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700 mb-2">Daily Activity Level</label>
              <div className="space-y-2">
                {ACTIVITY_LEVELS.map((level) => (
                  <button
                    key={level.id}
                    onClick={() => setOnboardingData({ activityLevel: level.id })}
                    className={`w-full p-3 text-left rounded-lg border-2 transition-colors ${
                      onboardingData.activityLevel === level.id
                        ? 'border-primary bg-primary/5'
                        : 'border-gray-200 hover:border-gray-300'
                    }`}
                  >
                    <div className="font-semibold text-gray-900">{level.label}</div>
                    <div className="text-sm text-gray-600">{level.desc}</div>
                  </button>
                ))}
              </div>
            </div>
          </div>
        )}

        {/* Navigation */}
        <div className="flex gap-4 mt-8">
          {step > 0 && (
            <button
              onClick={() => setStep(step - 1)}
              className="flex-1 py-3 px-6 border border-gray-300 rounded-lg text-gray-700 hover:bg-gray-50"
            >
              Back
            </button>
          )}
          <button
            onClick={handleNext}
            disabled={createUserMutation.isPending || isGenerating}
            className="flex-1 py-3 px-6 bg-primary text-white rounded-lg hover:bg-primary-dark disabled:opacity-50 disabled:cursor-not-allowed"
          >
            {step === 5 ? 'Create My Plan' : 'Next'}
          </button>
        </div>
      </div>
    </div>
  );
}
