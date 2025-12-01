// User types - matches backend schema
export interface UserBackend {
  id: number;
  username?: string;
  name?: string;
  onboarding_completed?: boolean;
  fitness_level: string;
  goals: string;  // JSON string
  equipment: string;  // JSON string
  preferences: string;  // JSON string
  active_injuries: string;  // JSON string
  created_at: string;
}

// Frontend-friendly User with parsed arrays
export interface User {
  id: number;
  username?: string;
  name?: string;
  fitness_level: string;
  goals: string[];
  equipment: string[];
  active_injuries: string[];
  onboarding_completed: boolean;
  created_at: string;
}

export interface CreateUserRequest {
  fitness_level: string;
  goals: string;  // JSON string
  equipment: string;  // JSON string
  preferences?: string;
  active_injuries?: string;
}

export interface UpdateUserRequest {
  fitness_level?: string;
  goals?: string;  // JSON string
  equipment?: string;  // JSON string
  preferences?: string;
  active_injuries?: string;
  onboarding_completed?: boolean;
}

// Helper to convert backend user to frontend user
export function parseUser(backend: UserBackend): User {
  return {
    id: backend.id,
    username: backend.username,
    name: backend.name,
    fitness_level: backend.fitness_level,
    goals: JSON.parse(backend.goals || '[]'),
    equipment: JSON.parse(backend.equipment || '[]'),
    active_injuries: JSON.parse(backend.active_injuries || '[]'),
    onboarding_completed: backend.onboarding_completed ?? true,
    created_at: backend.created_at,
  };
}

// Helper to extract OnboardingData from UserBackend preferences
export function extractOnboardingData(backend: UserBackend): Partial<OnboardingData> {
  const preferences = JSON.parse(backend.preferences || '{}');
  const goals = JSON.parse(backend.goals || '[]');
  const equipment = JSON.parse(backend.equipment || '[]');
  const activeInjuries = JSON.parse(backend.active_injuries || '[]');

  return {
    // Personal Info
    name: preferences.name || '',
    gender: preferences.gender || 'prefer_not_to_say',
    age: preferences.age || 30,

    // Body Metrics
    heightCm: preferences.height_cm || 170,
    weightKg: preferences.weight_kg || 70,
    targetWeightKg: preferences.target_weight_kg,

    // Advanced Measurements
    waistCircumferenceCm: preferences.waist_circumference_cm,
    hipCircumferenceCm: preferences.hip_circumference_cm,
    neckCircumferenceCm: preferences.neck_circumference_cm,
    bodyFatPercent: preferences.body_fat_percent,
    restingHeartRate: preferences.resting_heart_rate,
    bloodPressureSystolic: preferences.blood_pressure_systolic,
    bloodPressureDiastolic: preferences.blood_pressure_diastolic,

    // Fitness Background
    fitnessLevel: (backend.fitness_level as OnboardingData['fitnessLevel']) || 'beginner',
    goals: goals,
    workoutExperience: preferences.workout_experience || [],

    // Schedule
    daysPerWeek: preferences.days_per_week || 4,
    selectedDays: preferences.selected_days || [0, 1, 3, 4],
    preferredTime: preferences.preferred_time || 'morning',
    workoutDuration: preferences.workout_duration || 45,

    // Workout Preferences
    trainingSplit: preferences.training_split || 'full_body',
    intensityPreference: preferences.intensity_preference || 'moderate',
    equipment: equipment,
    workoutVariety: preferences.workout_variety || 'varied',

    // Health & Limitations
    activeInjuries: activeInjuries,
    healthConditions: preferences.health_conditions || [],
    activityLevel: preferences.activity_level || 'lightly_active',
  };
}

// Exercise types
export interface Exercise {
  id: string;
  name: string;
  description: string;
  muscle_groups: string[];
  equipment: string[];
  difficulty: 'beginner' | 'intermediate' | 'advanced';
  instructions: string[];
  video_url?: string;
  image_url?: string;
}

// Workout types
export interface WorkoutExercise {
  exercise_id: string;
  name: string;
  sets: number;
  reps: number;
  weight?: number;
  duration_seconds?: number;
  rest_seconds: number;
  notes?: string;
  completed?: boolean;
  muscle_group?: string;  // Primary muscle targeted by this exercise
  equipment?: string;     // Equipment needed for this exercise
  gif_url?: string;       // Exercise demonstration GIF from S3
}

// Backend workout type (has exercises_json as string)
export interface WorkoutBackend {
  id: string;  // UUID string from Supabase
  user_id: string;  // UUID string from Supabase
  name: string;
  type: 'strength' | 'cardio' | 'flexibility' | 'hiit' | 'mixed';
  difficulty: 'easy' | 'medium' | 'hard';
  duration_minutes: number;
  exercises_json: string;
  target_muscles_json?: string;  // JSON string of target muscles
  scheduled_date?: string;
  is_completed?: boolean;        // Backend uses boolean flag
  completed_at?: string;         // Legacy field (may not be set)
  notes?: string;
  created_at: string;
}

// Frontend-friendly Workout with parsed exercises array
export interface Workout {
  id: string;  // UUID string from Supabase
  user_id: string;  // UUID string from Supabase
  name: string;
  type: 'strength' | 'cardio' | 'flexibility' | 'hiit' | 'mixed';
  difficulty: 'easy' | 'medium' | 'hard';
  duration_minutes: number;
  exercises: WorkoutExercise[];
  target_muscles?: string[];  // Primary muscles targeted by this workout
  equipment?: string[];       // Equipment needed for this workout
  scheduled_date?: string;
  completed_at?: string;
  notes?: string;
  created_at: string;
}

// Helper to extract parent muscle name from format like "Quadriceps (Quadriceps Femoris)"
function extractParentMuscle(muscle: string): string {
  // Remove anything in parentheses and trim
  const parenthesisIndex = muscle.indexOf('(');
  if (parenthesisIndex > 0) {
    return muscle.substring(0, parenthesisIndex).trim();
  }
  return muscle.trim();
}

// Helper to convert backend workout to frontend workout
export function parseWorkout(backend: WorkoutBackend): Workout {
  const exercises = JSON.parse(backend.exercises_json || '[]') as WorkoutExercise[];

  // Extract target muscles from target_muscles_json if available,
  // otherwise derive from exercise muscle_group fields
  // Also simplify to parent muscle names only
  let target_muscles: string[] | undefined;
  if (backend.target_muscles_json) {
    const rawMuscles = JSON.parse(backend.target_muscles_json) as string[];
    const simplifiedMuscles = new Set<string>();
    rawMuscles.forEach(m => {
      const parent = extractParentMuscle(m).toLowerCase();
      if (parent) simplifiedMuscles.add(parent);
    });
    target_muscles = Array.from(simplifiedMuscles);
  } else {
    // Derive from exercises' muscle_group field
    const muscleSet = new Set<string>();
    exercises.forEach(ex => {
      if (ex.muscle_group) {
        const parent = extractParentMuscle(ex.muscle_group).toLowerCase();
        if (parent) muscleSet.add(parent);
      }
    });
    if (muscleSet.size > 0) {
      target_muscles = Array.from(muscleSet);
    }
  }

  // Extract unique equipment from exercises
  const equipmentSet = new Set<string>();
  exercises.forEach(ex => {
    if (ex.equipment && ex.equipment.toLowerCase() !== 'body weight') {
      equipmentSet.add(ex.equipment.toLowerCase());
    }
  });
  const equipment = equipmentSet.size > 0 ? Array.from(equipmentSet) : undefined;

  // Derive completed_at from is_completed flag if not already set
  // Backend uses is_completed boolean, frontend expects completed_at timestamp
  const completed_at = backend.completed_at || (backend.is_completed ? new Date().toISOString() : undefined);

  return {
    id: backend.id,
    user_id: backend.user_id,
    name: backend.name,
    type: backend.type,
    difficulty: backend.difficulty,
    duration_minutes: backend.duration_minutes ?? 45, // Default to 45 min if missing
    exercises,
    target_muscles,
    equipment,
    scheduled_date: backend.scheduled_date,
    completed_at,
    notes: backend.notes,
    created_at: backend.created_at,
  };
}

export interface GenerateWorkoutRequest {
  user_id: number;
  workout_type?: string;
  duration_minutes?: number;
  focus_areas?: string[];
  exclude_exercises?: string[];
  // Onboarding data for personalized AI generation
  fitness_level?: string;
  goals?: string[];
  equipment?: string[];
  replace_today?: boolean;  // If true, delete existing today's workout first
}

export interface GenerateWeeklyRequest {
  user_id: number;
  week_start_date: string;  // ISO date string, e.g., "2024-11-25"
  selected_days: number[];  // 0=Mon, 1=Tue, etc.
  duration_minutes?: number;
}

export interface GenerateWeeklyResponse {
  workouts: Workout[];
}

export interface GenerateMonthlyRequest {
  user_id: string;  // UUID string from Supabase
  month_start_date: string;  // ISO date string, e.g., "2024-11-01"
  selected_days: number[];   // 0=Mon, 1=Tue, ..., 6=Sun
  duration_minutes?: number;
  weeks?: number;  // Number of weeks to generate (default 12)
}

export interface GenerateMonthlyResponse {
  workouts: Workout[];
  total_generated: number;
}

// Chat types
export type CoachIntent =
  | 'add_exercise'
  | 'remove_exercise'
  | 'swap_workout'
  | 'modify_intensity'
  | 'reschedule'
  | 'report_injury'
  | 'delete_workout'
  | 'question';

export interface UserProfile {
  id: number;
  fitness_level: string;
  goals: string[];
  equipment: string[];
  active_injuries: string[];
}

export interface WorkoutContext {
  id: string;  // UUID string to match Workout.id
  name: string;
  type: string;
  difficulty: string;
  exercises: WorkoutExercise[];
  scheduled_date?: string;
  is_completed?: boolean;
}

export interface WorkoutScheduleContext {
  yesterday: WorkoutContext | null;
  today: WorkoutContext | null;
  tomorrow: WorkoutContext | null;
  thisWeek: WorkoutContext[];
  recentCompleted: WorkoutContext[];
}

export interface ChatMessage {
  role: 'user' | 'assistant';
  content: string;
  intent?: CoachIntent;
  actionData?: Record<string, unknown>;
}

export interface ChatRequest {
  message: string;
  user_id: number;
  user_profile?: UserProfile;
  current_workout?: WorkoutContext;
  workout_schedule?: WorkoutScheduleContext;
  conversation_history: ChatMessage[];
}

export interface ChatResponse {
  message: string;
  intent: CoachIntent;
  action_data?: Record<string, unknown>;
  rag_context_used: boolean;
  similar_questions: string[];
}

// Chat history item from database
export interface ChatHistoryItem {
  id: number;
  role: 'user' | 'assistant';
  content: string;
  timestamp: string;
  action_data?: Record<string, unknown>;
}

// Performance types
export interface PerformanceLog {
  id: number;
  user_id: string;  // UUID string from Supabase
  workout_id: string;  // UUID string from Supabase
  exercise_id: string;
  sets_completed: number;
  reps_completed: number[];
  weights_used: number[];
  notes?: string;
  logged_at: string;
}

export interface PerformanceStats {
  total_workouts: number;
  total_exercises: number;
  streak_days: number;
  favorite_exercises: string[];
  progress_by_muscle_group: Record<string, number>;
}

// Onboarding types
export interface OnboardingData {
  // Screen 1: Personal Info
  name: string;
  gender: 'male' | 'female' | 'other' | 'prefer_not_to_say';
  age: number;

  // Screen 2: Body Metrics
  heightCm: number;
  weightKg: number;
  targetWeightKg?: number;

  // Screen 2b: Advanced Body Measurements (collapsible/optional)
  waistCircumferenceCm?: number;
  hipCircumferenceCm?: number;
  neckCircumferenceCm?: number;
  bodyFatPercent?: number;
  restingHeartRate?: number;
  bloodPressureSystolic?: number;
  bloodPressureDiastolic?: number;

  // Screen 3: Fitness Background
  fitnessLevel: 'beginner' | 'intermediate' | 'advanced';
  goals: string[];
  workoutExperience: string[];

  // Screen 4: Schedule
  daysPerWeek: number;
  selectedDays: number[];  // 0=Mon, 1=Tue, ..., 6=Sun
  preferredTime: 'morning' | 'afternoon' | 'evening';
  workoutDuration: number;

  // Screen 5: Workout Preferences
  trainingSplit: 'full_body' | 'upper_lower' | 'push_pull_legs' | 'body_part';
  intensityPreference: 'light' | 'moderate' | 'intense';
  equipment: string[];
  workoutVariety: 'consistent' | 'varied';

  // Screen 6: Health & Limitations
  activeInjuries: string[];
  healthConditions: string[];
  activityLevel: 'sedentary' | 'lightly_active' | 'moderately_active' | 'very_active';
}

// Health Metrics types (calculated from body measurements)
export interface HealthMetrics {
  // BMI
  bmi: number;
  bmiCategory: 'underweight' | 'normal' | 'overweight' | 'obese';
  targetBmi?: number;

  // Ideal Body Weight (multiple formulas)
  idealBodyWeightDevine: number;
  idealBodyWeightRobinson: number;
  idealBodyWeightMiller: number;

  // Metabolic rates
  bmrMifflin: number;  // Mifflin-St Jeor (most accurate)
  bmrHarris: number;   // Harris-Benedict (alternative)
  tdee: number;        // Total Daily Energy Expenditure

  // Body composition (optional - requires additional measurements)
  waistToHeightRatio?: number;
  waistToHipRatio?: number;
  bodyFatNavy?: number;  // Calculated via Navy method
  leanBodyMass?: number;
  ffmi?: number;  // Fat-Free Mass Index
}

export interface MetricsInput {
  userId: number;
  weightKg: number;
  heightCm: number;
  age: number;
  gender: 'male' | 'female';
  activityLevel: 'sedentary' | 'lightly_active' | 'moderately_active' | 'very_active' | 'extremely_active';
  targetWeightKg?: number;
  waistCm?: number;
  hipCm?: number;
  neckCm?: number;
  bodyFatPercent?: number;
}

export interface MetricsHistoryEntry {
  id: number;
  userId: number;
  recordedAt: string;
  weightKg?: number;
  waistCm?: number;
  hipCm?: number;
  neckCm?: number;
  bodyFatMeasured?: number;
  restingHeartRate?: number;
  bloodPressureSystolic?: number;
  bloodPressureDiastolic?: number;
  bmi?: number;
  bmiCategory?: string;
  bmr?: number;
  tdee?: number;
  bodyFatCalculated?: number;
  leanBodyMass?: number;
  ffmi?: number;
  waistToHeightRatio?: number;
  waistToHipRatio?: number;
  idealBodyWeight?: number;
  notes?: string;
}

// Injury types
export interface ActiveInjury {
  id: number;
  bodyPart: string;
  severity: 'mild' | 'moderate' | 'severe';
  reportedAt: string;
  expectedRecoveryDate: string;
  currentPhase: 'acute' | 'subacute' | 'recovery' | 'healed';
  phaseDescription: string;
  allowedIntensity: 'none' | 'light' | 'moderate' | 'full';
  daysSinceInjury: number;
  daysRemaining: number;
  progressPercent: number;
  painLevel?: number;
  rehabExercises: string[];
}

// API Response types
export interface ApiError {
  detail: string;
}

export interface HealthResponse {
  status: string;
  database: string;
  version: string;
}

// ============================================
// Active Workout & Performance Tracking Types
// ============================================

// Set tracking during active workout
export interface ActiveSet {
  setNumber: number;
  setType: 'warmup' | 'working' | 'failure';
  targetWeight: number;
  targetReps: number;
  actualWeight: number | null;
  actualReps: number | null;
  isCompleted: boolean;
  previousWeight?: number;
  previousReps?: number;
  // Timing fields
  startTime?: number;        // Timestamp when set started
  endTime?: number;          // Timestamp when set completed
  durationSeconds?: number;  // Calculated duration
  previousDuration?: number; // Previous best time for same weight/reps
}

// Workout log for backend (records a completed workout session)
export interface WorkoutLogCreate {
  workout_id: string;
  user_id: string;
  sets_json: string;  // JSON stringified array of all sets data
  total_time_seconds: number;
}

export interface WorkoutLog {
  id: string;
  workout_id: string;
  user_id: string;
  sets_json: string;
  completed_at: string;
  total_time_seconds: number;
}

// Performance log for backend (individual set data)
export interface PerformanceLogCreate {
  workout_log_id: string;
  user_id: string;
  exercise_id: string;
  exercise_name: string;
  set_number: number;
  reps_completed: number;
  weight_kg: number;
  set_type?: 'warmup' | 'working' | 'failure';  // Set type indicator
  rpe?: number;
  rir?: number;  // Reps in reserve
  is_completed: boolean;
  failed_at_rep?: number;
  notes?: string;
}

export interface PerformanceLogDetailed {
  id: string;
  workout_log_id: string;
  user_id: string;
  exercise_id: string;
  exercise_name: string;
  set_number: number;
  reps_completed: number;
  weight_kg: number;
  set_type?: 'warmup' | 'working' | 'failure';  // Set type indicator
  rpe?: number;
  rir?: number;
  is_completed: boolean;
  failed_at_rep?: number;
  notes?: string;
  recorded_at: string;
}

// ============================================
// Strength Records (Personal Records / PRs)
// ============================================

export interface StrengthRecordCreate {
  user_id: string;
  exercise_id: string;
  exercise_name: string;
  weight_kg: number;
  reps: number;
  estimated_1rm: number;
  rpe?: number;
  is_pr?: boolean;
}

export interface StrengthRecord {
  id: string;
  user_id: string;
  exercise_id: string;
  exercise_name: string;
  weight_kg: number;
  reps: number;
  estimated_1rm: number;
  rpe?: number;
  is_pr: boolean;
  achieved_at: string;
}

// ============================================
// Weekly Volume Tracking
// ============================================

export interface WeeklyVolume {
  id: string;
  user_id: string;
  muscle_group: string;
  week_number: number;
  year: number;
  total_sets: number;
  total_reps: number;
  total_volume_kg: number;
  frequency: number;
  target_sets?: number;
  recovery_status: string;
  updated_at: string;
}

// ============================================
// Exercise History (for "Previous" column)
// ============================================

export interface ExerciseHistoryEntry {
  workout_date: string;
  sets: {
    set_number: number;
    weight_kg: number;
    reps: number;
    rpe?: number;
  }[];
}
