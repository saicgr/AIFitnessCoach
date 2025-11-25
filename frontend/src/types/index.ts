// User types - matches backend schema
export interface UserBackend {
  id: number;
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
}

// Helper to convert backend user to frontend user
export function parseUser(backend: UserBackend): User {
  return {
    id: backend.id,
    fitness_level: backend.fitness_level,
    goals: JSON.parse(backend.goals || '[]'),
    equipment: JSON.parse(backend.equipment || '[]'),
    active_injuries: JSON.parse(backend.active_injuries || '[]'),
    onboarding_completed: true,
    created_at: backend.created_at,
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
}

// Backend workout type (has exercises_json as string)
export interface WorkoutBackend {
  id: number;
  user_id: number;
  name: string;
  type: 'strength' | 'cardio' | 'flexibility' | 'hiit' | 'mixed';
  difficulty: 'easy' | 'medium' | 'hard';
  duration_minutes: number;
  exercises_json: string;
  target_muscles_json?: string;  // JSON string of target muscles
  scheduled_date?: string;
  completed_at?: string;
  notes?: string;
  created_at: string;
}

// Frontend-friendly Workout with parsed exercises array
export interface Workout {
  id: number;
  user_id: number;
  name: string;
  type: 'strength' | 'cardio' | 'flexibility' | 'hiit' | 'mixed';
  difficulty: 'easy' | 'medium' | 'hard';
  duration_minutes: number;
  exercises: WorkoutExercise[];
  target_muscles?: string[];  // Primary muscles targeted by this workout
  scheduled_date?: string;
  completed_at?: string;
  notes?: string;
  created_at: string;
}

// Helper to convert backend workout to frontend workout
export function parseWorkout(backend: WorkoutBackend): Workout {
  const exercises = JSON.parse(backend.exercises_json || '[]') as WorkoutExercise[];

  // Extract target muscles from target_muscles_json if available,
  // otherwise derive from exercise muscle_group fields
  let target_muscles: string[] | undefined;
  if (backend.target_muscles_json) {
    target_muscles = JSON.parse(backend.target_muscles_json);
  } else {
    // Derive from exercises' muscle_group field
    const muscleSet = new Set<string>();
    exercises.forEach(ex => {
      if (ex.muscle_group) {
        muscleSet.add(ex.muscle_group.toLowerCase());
      }
    });
    if (muscleSet.size > 0) {
      target_muscles = Array.from(muscleSet);
    }
  }

  return {
    id: backend.id,
    user_id: backend.user_id,
    name: backend.name,
    type: backend.type,
    difficulty: backend.difficulty,
    duration_minutes: backend.duration_minutes ?? 45, // Default to 45 min if missing
    exercises,
    target_muscles,
    scheduled_date: backend.scheduled_date,
    completed_at: backend.completed_at,
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
  user_id: number;
  month_start_date: string;  // ISO date string, e.g., "2024-11-01"
  selected_days: number[];   // 0=Mon, 1=Tue, ..., 6=Sun
  duration_minutes?: number;
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
  | 'question';

export interface UserProfile {
  id: number;
  fitness_level: string;
  goals: string[];
  equipment: string[];
  active_injuries: string[];
}

export interface WorkoutContext {
  id: number;
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

// Performance types
export interface PerformanceLog {
  id: number;
  user_id: number;
  workout_id: number;
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

// API Response types
export interface ApiError {
  detail: string;
}

export interface HealthResponse {
  status: string;
  database: string;
  version: string;
}
