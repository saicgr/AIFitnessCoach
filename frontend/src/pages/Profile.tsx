import { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { useMutation } from '@tanstack/react-query';
import { useAppStore } from '../store';
import { updateUser } from '../api/client';
import { createLogger } from '../utils/logger';
import { GlassCard, GlassButton } from '../components/ui';

const log = createLogger('profile');

// Icon components
const Icons = {
  Back: () => (
    <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 19l-7-7 7-7" />
    </svg>
  ),
  User: () => (
    <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z" />
    </svg>
  ),
  Fitness: () => (
    <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M13 10V3L4 14h7v7l9-11h-7z" />
    </svg>
  ),
  Calendar: () => (
    <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z" />
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
  Check: () => (
    <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 13l4 4L19 7" />
    </svg>
  ),
  Edit: () => (
    <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15.232 5.232l3.536 3.536m-2.036-5.036a2.5 2.5 0 113.536 3.536L6.5 21.036H3v-3.572L16.732 3.732z" />
    </svg>
  ),
  ChevronDown: () => (
    <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 9l-7 7-7-7" />
    </svg>
  ),
};

// Section Header with Edit button
function SectionHeader({
  icon,
  title,
  isEditing,
  onEdit,
  onSave,
  onCancel,
  isSaving
}: {
  icon: React.ReactNode;
  title: string;
  isEditing: boolean;
  onEdit: () => void;
  onSave: () => void;
  onCancel: () => void;
  isSaving?: boolean;
}) {
  return (
    <div className="flex items-center justify-between mb-4">
      <div className="flex items-center gap-3">
        <div className="p-2 bg-primary/20 rounded-xl text-primary">
          {icon}
        </div>
        <h2 className="text-lg font-semibold text-text">{title}</h2>
      </div>
      {isEditing ? (
        <div className="flex gap-2">
          <button
            onClick={onCancel}
            disabled={isSaving}
            className="px-3 py-1.5 text-sm font-medium text-text-secondary hover:bg-white/10 rounded-lg transition-colors"
          >
            Cancel
          </button>
          <button
            onClick={onSave}
            disabled={isSaving}
            className="px-3 py-1.5 text-sm font-medium bg-primary text-white rounded-lg hover:bg-primary/80 transition-colors flex items-center gap-1"
          >
            {isSaving ? (
              <div className="w-4 h-4 border-2 border-white border-t-transparent rounded-full animate-spin" />
            ) : (
              <Icons.Check />
            )}
            Save
          </button>
        </div>
      ) : (
        <button
          onClick={onEdit}
          className="p-2 hover:bg-white/10 rounded-lg transition-colors text-text-secondary hover:text-text"
        >
          <Icons.Edit />
        </button>
      )}
    </div>
  );
}

// Multi-select chip component
function ChipSelector({
  options,
  selected,
  onChange,
  disabled,
}: {
  options: string[];
  selected: string[];
  onChange: (selected: string[]) => void;
  disabled?: boolean;
}) {
  const toggle = (option: string) => {
    if (disabled) return;
    if (selected.includes(option)) {
      onChange(selected.filter(s => s !== option));
    } else {
      onChange([...selected, option]);
    }
  };

  return (
    <div className="flex flex-wrap gap-2">
      {options.map(option => (
        <button
          key={option}
          onClick={() => toggle(option)}
          disabled={disabled}
          className={`px-3 py-1.5 rounded-full text-sm font-medium transition-all ${
            selected.includes(option)
              ? 'bg-primary text-white shadow-[0_0_10px_rgba(6,182,212,0.3)]'
              : 'bg-white/5 text-text-secondary border border-white/10 hover:bg-white/10'
          } ${disabled ? 'opacity-50 cursor-not-allowed' : ''}`}
        >
          {option}
        </button>
      ))}
    </div>
  );
}

// Day selector grid
function DaySelector({
  selected,
  onChange,
  disabled,
}: {
  selected: number[];
  onChange: (days: number[]) => void;
  disabled?: boolean;
}) {
  const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  const toggle = (index: number) => {
    if (disabled) return;
    if (selected.includes(index)) {
      onChange(selected.filter(d => d !== index));
    } else {
      onChange([...selected, index].sort());
    }
  };

  return (
    <div className="grid grid-cols-7 gap-2">
      {days.map((day, index) => (
        <button
          key={day}
          onClick={() => toggle(index)}
          disabled={disabled}
          className={`py-2 rounded-lg text-sm font-medium transition-all ${
            selected.includes(index)
              ? 'bg-primary text-white shadow-[0_0_10px_rgba(6,182,212,0.3)]'
              : 'bg-white/5 text-text-secondary border border-white/10 hover:bg-white/10'
          } ${disabled ? 'opacity-50 cursor-not-allowed' : ''}`}
        >
          {day}
        </button>
      ))}
    </div>
  );
}

// Constants
const GOALS_OPTIONS = [
  'Build Muscle', 'Lose Weight', 'Increase Strength', 'Improve Endurance',
  'Stay Active', 'Flexibility', 'Athletic Performance', 'General Health'
];

const EQUIPMENT_OPTIONS = [
  'Bodyweight Only', 'Dumbbells', 'Barbell', 'Resistance Bands',
  'Pull-up Bar', 'Kettlebell', 'Cable Machine', 'Full Gym'
];

const INJURIES_OPTIONS = [
  'Lower back pain', 'Shoulder issues', 'Knee problems', 'Wrist/elbow pain',
  'Neck pain', 'Hip issues', 'None'
];

const HEALTH_CONDITIONS_OPTIONS = [
  'High blood pressure', 'Heart condition', 'Diabetes', 'Asthma',
  'Arthritis', 'Pregnancy', 'Recent surgery', 'None'
];

export default function Profile() {
  const navigate = useNavigate();
  const { user, onboardingData, setOnboardingData, setUser } = useAppStore();

  // Editing states for each section
  const [editingPersonal, setEditingPersonal] = useState(false);
  const [editingFitness, setEditingFitness] = useState(false);
  const [editingSchedule, setEditingSchedule] = useState(false);
  const [editingHealth, setEditingHealth] = useState(false);
  const [editingMeasurements, setEditingMeasurements] = useState(false);
  const [showMeasurements, setShowMeasurements] = useState(false);

  // Local form state
  const [formData, setFormData] = useState({ ...onboardingData });

  // Reset form data when onboardingData changes
  useEffect(() => {
    setFormData({ ...onboardingData });
  }, [onboardingData]);

  // Update mutation
  const updateMutation = useMutation({
    mutationFn: async (data: typeof formData) => {
      if (!user) throw new Error('No user');

      // Build preferences JSON
      const preferences = JSON.stringify({
        days_per_week: data.daysPerWeek,
        workout_duration: data.workoutDuration,
        training_split: data.trainingSplit,
        intensity_preference: data.intensityPreference,
        preferred_time: data.preferredTime,
        selected_days: data.selectedDays,
        name: data.name,
        gender: data.gender,
        age: data.age,
        height_cm: data.heightCm,
        weight_kg: data.weightKg,
        target_weight_kg: data.targetWeightKg,
        waist_circumference_cm: data.waistCircumferenceCm,
        hip_circumference_cm: data.hipCircumferenceCm,
        neck_circumference_cm: data.neckCircumferenceCm,
        body_fat_percent: data.bodyFatPercent,
        resting_heart_rate: data.restingHeartRate,
        blood_pressure_systolic: data.bloodPressureSystolic,
        blood_pressure_diastolic: data.bloodPressureDiastolic,
        workout_experience: data.workoutExperience,
        workout_variety: data.workoutVariety,
        health_conditions: data.healthConditions,
        activity_level: data.activityLevel,
      });

      const updatedUser = await updateUser(user.id, {
        fitness_level: data.fitnessLevel,
        goals: JSON.stringify(data.goals),
        equipment: JSON.stringify(data.equipment),
        active_injuries: JSON.stringify(data.activeInjuries.filter(i => i !== 'None')),
        preferences,
      });

      return { updatedUser, data };
    },
    onSuccess: ({ updatedUser, data }) => {
      setUser(updatedUser);
      setOnboardingData(data);
      log.info('Profile updated successfully');
      // Close all editing states
      setEditingPersonal(false);
      setEditingFitness(false);
      setEditingSchedule(false);
      setEditingHealth(false);
      setEditingMeasurements(false);
    },
    onError: (error) => {
      log.error('Failed to update profile', error);
    },
  });

  const handleSave = (section: string) => {
    log.info(`Saving ${section} section`);
    updateMutation.mutate(formData);
  };

  const handleCancel = (section: string) => {
    setFormData({ ...onboardingData });
    switch (section) {
      case 'personal':
        setEditingPersonal(false);
        break;
      case 'fitness':
        setEditingFitness(false);
        break;
      case 'schedule':
        setEditingSchedule(false);
        break;
      case 'health':
        setEditingHealth(false);
        break;
      case 'measurements':
        setEditingMeasurements(false);
        break;
    }
  };

  if (!user) {
    navigate('/login');
    return null;
  }

  const userInitials = formData.name
    ? formData.name.split(' ').map(n => n[0]).join('').toUpperCase().slice(0, 2)
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
          <h1 className="text-lg font-semibold text-text">Profile</h1>
          <div className="w-9" />
        </div>
      </header>

      <main className="relative z-10 max-w-2xl mx-auto px-4 py-6 space-y-6">
        {/* Profile Header Card */}
        <div
          className="relative overflow-hidden rounded-2xl p-6 bg-gradient-to-br from-primary to-secondary"
          style={{
            boxShadow: '0 0 40px rgba(6, 182, 212, 0.3), 0 20px 40px rgba(0,0,0,0.3)',
          }}
        >
          <div className="flex items-center gap-4">
            <div className="w-20 h-20 bg-white/20 backdrop-blur rounded-2xl flex items-center justify-center text-2xl font-bold text-white">
              {userInitials}
            </div>
            <div className="flex-1">
              <h2 className="text-2xl font-bold text-white">{formData.name || 'Fitness Enthusiast'}</h2>
              <p className="text-white/70 capitalize">{user.fitness_level} Level</p>
              <p className="text-white/50 text-sm mt-1">Member since {new Date(user.created_at).toLocaleDateString()}</p>
            </div>
          </div>
        </div>

        {/* Personal Information Section */}
        <GlassCard className="p-6">
          <SectionHeader
            icon={<Icons.User />}
            title="Personal Information"
            isEditing={editingPersonal}
            onEdit={() => setEditingPersonal(true)}
            onSave={() => handleSave('personal')}
            onCancel={() => handleCancel('personal')}
            isSaving={updateMutation.isPending}
          />

          <div className="space-y-4">
            {/* Name */}
            <div>
              <label className="text-xs font-medium text-text-secondary uppercase tracking-wide">Name</label>
              {editingPersonal ? (
                <input
                  type="text"
                  value={formData.name}
                  onChange={(e) => setFormData({ ...formData, name: e.target.value })}
                  className="w-full mt-1 px-4 py-3 bg-white/5 border border-white/10 rounded-xl text-text focus:outline-none focus:border-primary focus:ring-1 focus:ring-primary"
                />
              ) : (
                <p className="text-text mt-1">{formData.name || 'Not set'}</p>
              )}
            </div>

            {/* Gender & Age Row */}
            <div className="grid grid-cols-2 gap-4">
              <div>
                <label className="text-xs font-medium text-text-secondary uppercase tracking-wide">Gender</label>
                {editingPersonal ? (
                  <select
                    value={formData.gender}
                    onChange={(e) => setFormData({ ...formData, gender: e.target.value as typeof formData.gender })}
                    className="w-full mt-1 px-4 py-3 bg-white/5 border border-white/10 rounded-xl text-text focus:outline-none focus:border-primary"
                  >
                    <option value="male">Male</option>
                    <option value="female">Female</option>
                    <option value="other">Other</option>
                    <option value="prefer_not_to_say">Prefer not to say</option>
                  </select>
                ) : (
                  <p className="text-text mt-1 capitalize">{formData.gender.replace('_', ' ')}</p>
                )}
              </div>
              <div>
                <label className="text-xs font-medium text-text-secondary uppercase tracking-wide">Age</label>
                {editingPersonal ? (
                  <input
                    type="number"
                    value={formData.age}
                    onChange={(e) => setFormData({ ...formData, age: parseInt(e.target.value) || 0 })}
                    min={13}
                    max={100}
                    className="w-full mt-1 px-4 py-3 bg-white/5 border border-white/10 rounded-xl text-text focus:outline-none focus:border-primary"
                  />
                ) : (
                  <p className="text-text mt-1">{formData.age} years</p>
                )}
              </div>
            </div>

            {/* Height & Weight Row */}
            <div className="grid grid-cols-2 gap-4">
              <div>
                <label className="text-xs font-medium text-text-secondary uppercase tracking-wide">Height</label>
                {editingPersonal ? (
                  <div className="flex gap-2 mt-1">
                    <input
                      type="number"
                      value={formData.heightCm}
                      onChange={(e) => setFormData({ ...formData, heightCm: parseInt(e.target.value) || 0 })}
                      className="flex-1 px-4 py-3 bg-white/5 border border-white/10 rounded-xl text-text focus:outline-none focus:border-primary"
                    />
                    <span className="px-3 py-3 bg-white/5 rounded-xl text-text-secondary">cm</span>
                  </div>
                ) : (
                  <p className="text-text mt-1">{formData.heightCm} cm</p>
                )}
              </div>
              <div>
                <label className="text-xs font-medium text-text-secondary uppercase tracking-wide">Weight</label>
                {editingPersonal ? (
                  <div className="flex gap-2 mt-1">
                    <input
                      type="number"
                      value={formData.weightKg}
                      onChange={(e) => setFormData({ ...formData, weightKg: parseFloat(e.target.value) || 0 })}
                      step="0.1"
                      className="flex-1 px-4 py-3 bg-white/5 border border-white/10 rounded-xl text-text focus:outline-none focus:border-primary"
                    />
                    <span className="px-3 py-3 bg-white/5 rounded-xl text-text-secondary">kg</span>
                  </div>
                ) : (
                  <p className="text-text mt-1">{formData.weightKg} kg</p>
                )}
              </div>
            </div>

            {/* Target Weight */}
            <div>
              <label className="text-xs font-medium text-text-secondary uppercase tracking-wide">Target Weight</label>
              {editingPersonal ? (
                <div className="flex gap-2 mt-1">
                  <input
                    type="number"
                    value={formData.targetWeightKg || ''}
                    onChange={(e) => setFormData({ ...formData, targetWeightKg: parseFloat(e.target.value) || undefined })}
                    step="0.1"
                    placeholder="Optional"
                    className="flex-1 px-4 py-3 bg-white/5 border border-white/10 rounded-xl text-text focus:outline-none focus:border-primary placeholder:text-text-muted"
                  />
                  <span className="px-3 py-3 bg-white/5 rounded-xl text-text-secondary">kg</span>
                </div>
              ) : (
                <p className="text-text mt-1">{formData.targetWeightKg ? `${formData.targetWeightKg} kg` : 'Not set'}</p>
              )}
            </div>
          </div>
        </GlassCard>

        {/* Fitness Settings Section */}
        <GlassCard className="p-6">
          <SectionHeader
            icon={<Icons.Fitness />}
            title="Fitness Settings"
            isEditing={editingFitness}
            onEdit={() => setEditingFitness(true)}
            onSave={() => handleSave('fitness')}
            onCancel={() => handleCancel('fitness')}
            isSaving={updateMutation.isPending}
          />

          <div className="space-y-5">
            {/* Fitness Level */}
            <div>
              <label className="text-xs font-medium text-text-secondary uppercase tracking-wide">Fitness Level</label>
              {editingFitness ? (
                <div className="flex gap-2 mt-2">
                  {['beginner', 'intermediate', 'advanced'].map(level => (
                    <button
                      key={level}
                      onClick={() => setFormData({ ...formData, fitnessLevel: level as typeof formData.fitnessLevel })}
                      className={`flex-1 py-2.5 rounded-xl text-sm font-medium transition-all capitalize ${
                        formData.fitnessLevel === level
                          ? 'bg-primary text-white shadow-[0_0_15px_rgba(6,182,212,0.4)]'
                          : 'bg-white/5 text-text-secondary border border-white/10 hover:bg-white/10'
                      }`}
                    >
                      {level}
                    </button>
                  ))}
                </div>
              ) : (
                <p className="text-text mt-1 capitalize">{formData.fitnessLevel}</p>
              )}
            </div>

            {/* Goals */}
            <div>
              <label className="text-xs font-medium text-text-secondary uppercase tracking-wide mb-2 block">Goals</label>
              {editingFitness ? (
                <ChipSelector
                  options={GOALS_OPTIONS}
                  selected={formData.goals}
                  onChange={(goals) => setFormData({ ...formData, goals })}
                />
              ) : (
                <div className="flex flex-wrap gap-2">
                  {formData.goals.map(goal => (
                    <span key={goal} className="px-3 py-1 bg-primary/20 text-primary rounded-full text-sm font-medium border border-primary/30">
                      {goal}
                    </span>
                  ))}
                  {formData.goals.length === 0 && <span className="text-text-muted">No goals set</span>}
                </div>
              )}
            </div>

            {/* Equipment */}
            <div>
              <label className="text-xs font-medium text-text-secondary uppercase tracking-wide mb-2 block">Available Equipment</label>
              {editingFitness ? (
                <ChipSelector
                  options={EQUIPMENT_OPTIONS}
                  selected={formData.equipment}
                  onChange={(equipment) => setFormData({ ...formData, equipment })}
                />
              ) : (
                <div className="flex flex-wrap gap-2">
                  {formData.equipment.map(item => (
                    <span key={item} className="px-3 py-1 bg-accent/20 text-accent rounded-full text-sm font-medium border border-accent/30">
                      {item}
                    </span>
                  ))}
                  {formData.equipment.length === 0 && <span className="text-text-muted">Bodyweight only</span>}
                </div>
              )}
            </div>

            {/* Training Split & Intensity */}
            <div className="grid grid-cols-2 gap-4">
              <div>
                <label className="text-xs font-medium text-text-secondary uppercase tracking-wide">Training Split</label>
                {editingFitness ? (
                  <select
                    value={formData.trainingSplit}
                    onChange={(e) => setFormData({ ...formData, trainingSplit: e.target.value as typeof formData.trainingSplit })}
                    className="w-full mt-1 px-4 py-3 bg-white/5 border border-white/10 rounded-xl text-text focus:outline-none focus:border-primary"
                  >
                    <option value="full_body">Full Body</option>
                    <option value="upper_lower">Upper/Lower</option>
                    <option value="push_pull_legs">Push/Pull/Legs</option>
                    <option value="body_part">Body Part Split</option>
                  </select>
                ) : (
                  <p className="text-text mt-1 capitalize">{formData.trainingSplit.replace('_', ' ')}</p>
                )}
              </div>
              <div>
                <label className="text-xs font-medium text-text-secondary uppercase tracking-wide">Intensity</label>
                {editingFitness ? (
                  <select
                    value={formData.intensityPreference}
                    onChange={(e) => setFormData({ ...formData, intensityPreference: e.target.value as typeof formData.intensityPreference })}
                    className="w-full mt-1 px-4 py-3 bg-white/5 border border-white/10 rounded-xl text-text focus:outline-none focus:border-primary"
                  >
                    <option value="light">Light</option>
                    <option value="moderate">Moderate</option>
                    <option value="intense">Intense</option>
                  </select>
                ) : (
                  <p className="text-text mt-1 capitalize">{formData.intensityPreference}</p>
                )}
              </div>
            </div>
          </div>
        </GlassCard>

        {/* Schedule Section */}
        <GlassCard className="p-6">
          <SectionHeader
            icon={<Icons.Calendar />}
            title="Workout Schedule"
            isEditing={editingSchedule}
            onEdit={() => setEditingSchedule(true)}
            onSave={() => handleSave('schedule')}
            onCancel={() => handleCancel('schedule')}
            isSaving={updateMutation.isPending}
          />

          <div className="space-y-5">
            {/* Workout Days */}
            <div>
              <label className="text-xs font-medium text-text-secondary uppercase tracking-wide mb-2 block">
                Workout Days ({formData.selectedDays.length} days/week)
              </label>
              <DaySelector
                selected={formData.selectedDays}
                onChange={(days) => setFormData({ ...formData, selectedDays: days, daysPerWeek: days.length })}
                disabled={!editingSchedule}
              />
            </div>

            {/* Time & Duration */}
            <div className="grid grid-cols-2 gap-4">
              <div>
                <label className="text-xs font-medium text-text-secondary uppercase tracking-wide">Preferred Time</label>
                {editingSchedule ? (
                  <select
                    value={formData.preferredTime}
                    onChange={(e) => setFormData({ ...formData, preferredTime: e.target.value as typeof formData.preferredTime })}
                    className="w-full mt-1 px-4 py-3 bg-white/5 border border-white/10 rounded-xl text-text focus:outline-none focus:border-primary"
                  >
                    <option value="morning">Morning</option>
                    <option value="afternoon">Afternoon</option>
                    <option value="evening">Evening</option>
                  </select>
                ) : (
                  <p className="text-text mt-1 capitalize">{formData.preferredTime}</p>
                )}
              </div>
              <div>
                <label className="text-xs font-medium text-text-secondary uppercase tracking-wide">Duration</label>
                {editingSchedule ? (
                  <select
                    value={formData.workoutDuration}
                    onChange={(e) => setFormData({ ...formData, workoutDuration: parseInt(e.target.value) })}
                    className="w-full mt-1 px-4 py-3 bg-white/5 border border-white/10 rounded-xl text-text focus:outline-none focus:border-primary"
                  >
                    <option value={30}>30 minutes</option>
                    <option value={45}>45 minutes</option>
                    <option value={60}>60 minutes</option>
                    <option value={75}>75 minutes</option>
                    <option value={90}>90 minutes</option>
                  </select>
                ) : (
                  <p className="text-text mt-1">{formData.workoutDuration} minutes</p>
                )}
              </div>
            </div>
          </div>
        </GlassCard>

        {/* Health & Limitations Section */}
        <GlassCard className="p-6">
          <SectionHeader
            icon={<Icons.Heart />}
            title="Health & Limitations"
            isEditing={editingHealth}
            onEdit={() => setEditingHealth(true)}
            onSave={() => handleSave('health')}
            onCancel={() => handleCancel('health')}
            isSaving={updateMutation.isPending}
          />

          <div className="space-y-5">
            {/* Activity Level */}
            <div>
              <label className="text-xs font-medium text-text-secondary uppercase tracking-wide">Daily Activity Level</label>
              {editingHealth ? (
                <select
                  value={formData.activityLevel}
                  onChange={(e) => setFormData({ ...formData, activityLevel: e.target.value as typeof formData.activityLevel })}
                  className="w-full mt-1 px-4 py-3 bg-white/5 border border-white/10 rounded-xl text-text focus:outline-none focus:border-primary"
                >
                  <option value="sedentary">Sedentary (desk job)</option>
                  <option value="lightly_active">Lightly Active</option>
                  <option value="moderately_active">Moderately Active</option>
                  <option value="very_active">Very Active</option>
                </select>
              ) : (
                <p className="text-text mt-1 capitalize">{formData.activityLevel.replace('_', ' ')}</p>
              )}
            </div>

            {/* Injuries */}
            <div>
              <label className="text-xs font-medium text-text-secondary uppercase tracking-wide mb-2 block">Current Injuries/Pain</label>
              {editingHealth ? (
                <ChipSelector
                  options={INJURIES_OPTIONS}
                  selected={formData.activeInjuries}
                  onChange={(injuries) => {
                    // If "None" is selected, clear others. If anything else selected, remove "None"
                    if (injuries.includes('None') && !formData.activeInjuries.includes('None')) {
                      setFormData({ ...formData, activeInjuries: ['None'] });
                    } else {
                      setFormData({ ...formData, activeInjuries: injuries.filter(i => i !== 'None') });
                    }
                  }}
                />
              ) : (
                <div className="flex flex-wrap gap-2">
                  {formData.activeInjuries.length > 0 ? (
                    formData.activeInjuries.map(injury => (
                      <span key={injury} className="px-3 py-1 bg-orange/20 text-orange rounded-full text-sm font-medium border border-orange/30">
                        {injury}
                      </span>
                    ))
                  ) : (
                    <span className="text-text-muted">None reported</span>
                  )}
                </div>
              )}
            </div>

            {/* Health Conditions */}
            <div>
              <label className="text-xs font-medium text-text-secondary uppercase tracking-wide mb-2 block">Health Conditions</label>
              {editingHealth ? (
                <ChipSelector
                  options={HEALTH_CONDITIONS_OPTIONS}
                  selected={formData.healthConditions}
                  onChange={(conditions) => {
                    if (conditions.includes('None') && !formData.healthConditions.includes('None')) {
                      setFormData({ ...formData, healthConditions: ['None'] });
                    } else {
                      setFormData({ ...formData, healthConditions: conditions.filter(c => c !== 'None') });
                    }
                  }}
                />
              ) : (
                <div className="flex flex-wrap gap-2">
                  {formData.healthConditions.length > 0 ? (
                    formData.healthConditions.map(condition => (
                      <span key={condition} className="px-3 py-1 bg-coral/20 text-coral rounded-full text-sm font-medium border border-coral/30">
                        {condition}
                      </span>
                    ))
                  ) : (
                    <span className="text-text-muted">None reported</span>
                  )}
                </div>
              )}
            </div>
          </div>
        </GlassCard>

        {/* Advanced Measurements Section (Collapsible) */}
        <GlassCard className="p-6">
          <button
            onClick={() => setShowMeasurements(!showMeasurements)}
            className="w-full flex items-center justify-between"
          >
            <div className="flex items-center gap-3">
              <div className="p-2 bg-secondary/20 rounded-xl text-secondary">
                <Icons.Scale />
              </div>
              <div className="text-left">
                <h2 className="text-lg font-semibold text-text">Advanced Measurements</h2>
                <p className="text-xs text-text-secondary">Body composition data (optional)</p>
              </div>
            </div>
            <div className={`transform transition-transform ${showMeasurements ? 'rotate-180' : ''}`}>
              <Icons.ChevronDown />
            </div>
          </button>

          {showMeasurements && (
            <div className="mt-6 pt-6 border-t border-white/10">
              <div className="flex justify-end mb-4">
                {editingMeasurements ? (
                  <div className="flex gap-2">
                    <button
                      onClick={() => handleCancel('measurements')}
                      disabled={updateMutation.isPending}
                      className="px-3 py-1.5 text-sm font-medium text-text-secondary hover:bg-white/10 rounded-lg transition-colors"
                    >
                      Cancel
                    </button>
                    <button
                      onClick={() => handleSave('measurements')}
                      disabled={updateMutation.isPending}
                      className="px-3 py-1.5 text-sm font-medium bg-primary text-white rounded-lg hover:bg-primary/80 transition-colors flex items-center gap-1"
                    >
                      {updateMutation.isPending ? (
                        <div className="w-4 h-4 border-2 border-white border-t-transparent rounded-full animate-spin" />
                      ) : (
                        <Icons.Check />
                      )}
                      Save
                    </button>
                  </div>
                ) : (
                  <button
                    onClick={() => setEditingMeasurements(true)}
                    className="p-2 hover:bg-white/10 rounded-lg transition-colors text-text-secondary hover:text-text"
                  >
                    <Icons.Edit />
                  </button>
                )}
              </div>

              <div className="grid grid-cols-2 gap-4">
                {/* Waist */}
                <div>
                  <label className="text-xs font-medium text-text-secondary uppercase tracking-wide">Waist</label>
                  {editingMeasurements ? (
                    <div className="flex gap-2 mt-1">
                      <input
                        type="number"
                        value={formData.waistCircumferenceCm || ''}
                        onChange={(e) => setFormData({ ...formData, waistCircumferenceCm: parseFloat(e.target.value) || undefined })}
                        placeholder="cm"
                        className="flex-1 px-4 py-3 bg-white/5 border border-white/10 rounded-xl text-text focus:outline-none focus:border-primary placeholder:text-text-muted"
                      />
                    </div>
                  ) : (
                    <p className="text-text mt-1">{formData.waistCircumferenceCm ? `${formData.waistCircumferenceCm} cm` : 'Not set'}</p>
                  )}
                </div>

                {/* Hip */}
                <div>
                  <label className="text-xs font-medium text-text-secondary uppercase tracking-wide">Hip</label>
                  {editingMeasurements ? (
                    <input
                      type="number"
                      value={formData.hipCircumferenceCm || ''}
                      onChange={(e) => setFormData({ ...formData, hipCircumferenceCm: parseFloat(e.target.value) || undefined })}
                      placeholder="cm"
                      className="w-full mt-1 px-4 py-3 bg-white/5 border border-white/10 rounded-xl text-text focus:outline-none focus:border-primary placeholder:text-text-muted"
                    />
                  ) : (
                    <p className="text-text mt-1">{formData.hipCircumferenceCm ? `${formData.hipCircumferenceCm} cm` : 'Not set'}</p>
                  )}
                </div>

                {/* Neck */}
                <div>
                  <label className="text-xs font-medium text-text-secondary uppercase tracking-wide">Neck</label>
                  {editingMeasurements ? (
                    <input
                      type="number"
                      value={formData.neckCircumferenceCm || ''}
                      onChange={(e) => setFormData({ ...formData, neckCircumferenceCm: parseFloat(e.target.value) || undefined })}
                      placeholder="cm"
                      className="w-full mt-1 px-4 py-3 bg-white/5 border border-white/10 rounded-xl text-text focus:outline-none focus:border-primary placeholder:text-text-muted"
                    />
                  ) : (
                    <p className="text-text mt-1">{formData.neckCircumferenceCm ? `${formData.neckCircumferenceCm} cm` : 'Not set'}</p>
                  )}
                </div>

                {/* Body Fat */}
                <div>
                  <label className="text-xs font-medium text-text-secondary uppercase tracking-wide">Body Fat %</label>
                  {editingMeasurements ? (
                    <input
                      type="number"
                      value={formData.bodyFatPercent || ''}
                      onChange={(e) => setFormData({ ...formData, bodyFatPercent: parseFloat(e.target.value) || undefined })}
                      placeholder="%"
                      step="0.1"
                      className="w-full mt-1 px-4 py-3 bg-white/5 border border-white/10 rounded-xl text-text focus:outline-none focus:border-primary placeholder:text-text-muted"
                    />
                  ) : (
                    <p className="text-text mt-1">{formData.bodyFatPercent ? `${formData.bodyFatPercent}%` : 'Not set'}</p>
                  )}
                </div>

                {/* Resting HR */}
                <div>
                  <label className="text-xs font-medium text-text-secondary uppercase tracking-wide">Resting HR</label>
                  {editingMeasurements ? (
                    <div className="flex gap-2 mt-1">
                      <input
                        type="number"
                        value={formData.restingHeartRate || ''}
                        onChange={(e) => setFormData({ ...formData, restingHeartRate: parseInt(e.target.value) || undefined })}
                        placeholder="bpm"
                        className="flex-1 px-4 py-3 bg-white/5 border border-white/10 rounded-xl text-text focus:outline-none focus:border-primary placeholder:text-text-muted"
                      />
                    </div>
                  ) : (
                    <p className="text-text mt-1">{formData.restingHeartRate ? `${formData.restingHeartRate} bpm` : 'Not set'}</p>
                  )}
                </div>

                {/* Blood Pressure */}
                <div>
                  <label className="text-xs font-medium text-text-secondary uppercase tracking-wide">Blood Pressure</label>
                  {editingMeasurements ? (
                    <div className="flex gap-2 mt-1">
                      <input
                        type="number"
                        value={formData.bloodPressureSystolic || ''}
                        onChange={(e) => setFormData({ ...formData, bloodPressureSystolic: parseInt(e.target.value) || undefined })}
                        placeholder="Sys"
                        className="flex-1 px-4 py-3 bg-white/5 border border-white/10 rounded-xl text-text focus:outline-none focus:border-primary placeholder:text-text-muted"
                      />
                      <span className="py-3 text-text-muted">/</span>
                      <input
                        type="number"
                        value={formData.bloodPressureDiastolic || ''}
                        onChange={(e) => setFormData({ ...formData, bloodPressureDiastolic: parseInt(e.target.value) || undefined })}
                        placeholder="Dia"
                        className="flex-1 px-4 py-3 bg-white/5 border border-white/10 rounded-xl text-text focus:outline-none focus:border-primary placeholder:text-text-muted"
                      />
                    </div>
                  ) : (
                    <p className="text-text mt-1">
                      {formData.bloodPressureSystolic && formData.bloodPressureDiastolic
                        ? `${formData.bloodPressureSystolic}/${formData.bloodPressureDiastolic} mmHg`
                        : 'Not set'}
                    </p>
                  )}
                </div>
              </div>
            </div>
          )}
        </GlassCard>

        {/* Quick Actions */}
        <div className="flex gap-3">
          <GlassButton
            variant="secondary"
            onClick={() => navigate('/settings')}
            fullWidth
          >
            Settings
          </GlassButton>
          <GlassButton
            variant="primary"
            onClick={() => navigate('/metrics')}
            fullWidth
          >
            View Metrics
          </GlassButton>
        </div>
      </main>

      {/* Error Toast */}
      {updateMutation.isError && (
        <div className="fixed bottom-6 left-4 right-4 z-50">
          <GlassCard className="p-4 border-coral/30" variant="default">
            <div className="flex items-center gap-3">
              <svg className="w-5 h-5 text-coral flex-shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
              </svg>
              <span className="flex-1 text-sm text-text">Failed to save changes. Please try again.</span>
            </div>
          </GlassCard>
        </div>
      )}

      {/* Success Toast */}
      {updateMutation.isSuccess && (
        <div className="fixed bottom-6 left-4 right-4 z-50 animate-fade-in">
          <GlassCard className="p-4 border-accent/30" variant="default">
            <div className="flex items-center gap-3">
              <svg className="w-5 h-5 text-accent flex-shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 13l4 4L19 7" />
              </svg>
              <span className="flex-1 text-sm text-text">Profile updated successfully!</span>
            </div>
          </GlassCard>
        </div>
      )}
    </div>
  );
}
