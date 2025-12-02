import axios from 'axios';
import type {
  User,
  UserBackend,
  CreateUserRequest,
  UpdateUserRequest,
  Workout,
  WorkoutBackend,
  GenerateWorkoutRequest,
  GenerateWeeklyRequest,
  GenerateMonthlyRequest,
  GenerateMonthlyResponse,
  ChatRequest,
  ChatResponse,
  ChatHistoryItem,
  Exercise,
  PerformanceLog,
  PerformanceStats,
  HealthResponse,
  HealthMetrics,
  MetricsInput,
  ActiveInjury,
  // New types for performance tracking
  WorkoutLogCreate,
  WorkoutLog,
  PerformanceLogCreate,
  PerformanceLogDetailed,
  StrengthRecordCreate,
  StrengthRecord,
  WeeklyVolume,
} from '../types';
import { parseUser, parseWorkout } from '../types';
import { createLogger } from '../utils/logger';
import { useAppStore } from '../store';

const log = createLogger('api');

const api = axios.create({
  baseURL: '/api/v1',
  headers: {
    'Content-Type': 'application/json',
  },
});

// Add auth token to requests
api.interceptors.request.use(
  (config) => {
    const session = useAppStore.getState().session;
    if (session?.access_token) {
      config.headers.Authorization = `Bearer ${session.access_token}`;
    }
    return config;
  },
  (error) => {
    return Promise.reject(error);
  }
);

// Request interceptor - log outgoing requests
api.interceptors.request.use(
  (config) => {
    log.info(`Request: ${config.method?.toUpperCase()} ${config.url}`);
    if (config.data) {
      log.debug('Request data', config.data);
    }
    return config;
  },
  (error) => {
    log.error('Request error', error);
    return Promise.reject(error);
  }
);

// Response interceptor - log responses
api.interceptors.response.use(
  (response) => {
    log.info(`Response: ${response.status} ${response.config.url}`);
    if (response.data) {
      log.debug('Response data', response.data);
    }
    return response;
  },
  (error) => {
    log.error(`Error: ${error.response?.status || 'Network Error'} ${error.config?.url}`, error.response?.data);
    return Promise.reject(error);
  }
);

// Health
export const checkHealth = async (): Promise<HealthResponse> => {
  const { data } = await api.get('/health/');
  return data;
};

// Auth - returns both parsed User and raw backend data for extracting onboarding preferences
export const googleAuth = async (accessToken: string): Promise<{ user: User; backend: UserBackend }> => {
  const { data } = await api.post<UserBackend>('/users/auth/google', { access_token: accessToken });
  return { user: parseUser(data), backend: data };
};

// Users
export const createUser = async (user: CreateUserRequest): Promise<User> => {
  const { data } = await api.post<UserBackend>('/users/', user);
  return parseUser(data);
};

export const getUser = async (userId: number): Promise<User> => {
  const { data } = await api.get<UserBackend>(`/users/${userId}`);
  return parseUser(data);
};

// Get user with raw backend data for extracting onboarding preferences
export const getUserWithBackend = async (userId: number | string): Promise<{ user: User; backend: UserBackend }> => {
  const { data } = await api.get<UserBackend>(`/users/${userId}`);
  return { user: parseUser(data), backend: data };
};

export const updateUser = async (userId: number, updates: UpdateUserRequest): Promise<User> => {
  const { data } = await api.put<UserBackend>(`/users/${userId}`, updates);
  return parseUser(data);
};

export const resetUser = async (userId: number): Promise<void> => {
  await api.delete(`/users/${userId}/reset`);
};

export const loginAsDemoUser = async (): Promise<User> => {
  const { data } = await api.post<UserBackend>('/users/demo');
  return parseUser(data);
};

// Workouts
export const getWorkouts = async (userId: number): Promise<Workout[]> => {
  const { data } = await api.get<WorkoutBackend[]>(`/workouts-db/?user_id=${userId}`);
  return data.map(parseWorkout);
};

export const getWorkout = async (workoutId: string): Promise<Workout> => {
  const { data } = await api.get<WorkoutBackend>(`/workouts-db/${workoutId}`);
  return parseWorkout(data);
};

export const generateWorkout = async (request: GenerateWorkoutRequest): Promise<Workout> => {
  const { data } = await api.post<WorkoutBackend>('/workouts-db/generate', request);
  return parseWorkout(data);
};

export const generateWeeklyWorkouts = async (request: GenerateWeeklyRequest): Promise<Workout[]> => {
  const { data } = await api.post<{ workouts: WorkoutBackend[] }>('/workouts-db/generate-weekly', request);
  return data.workouts.map(parseWorkout);
};

export const generateMonthlyWorkouts = async (request: GenerateMonthlyRequest): Promise<GenerateMonthlyResponse> => {
  // 5 minute timeout for generating 12 weeks of workouts (many AI calls)
  const { data } = await api.post<{ workouts: WorkoutBackend[]; total_generated: number }>(
    '/workouts-db/generate-monthly',
    request,
    { timeout: 300000 }  // 5 minutes
  );
  return {
    workouts: data.workouts.map(parseWorkout),
    total_generated: data.total_generated,
  };
};

export const generateRemainingWorkouts = async (request: GenerateMonthlyRequest): Promise<GenerateMonthlyResponse> => {
  const { data } = await api.post<{ workouts: WorkoutBackend[]; total_generated: number }>('/workouts-db/generate-remaining', request);
  return {
    workouts: data.workouts.map(parseWorkout),
    total_generated: data.total_generated,
  };
};

// Background workout generation - runs on the server and doesn't depend on client connection
export interface ScheduleBackgroundGenerationRequest {
  user_id: string;
  month_start_date: string;
  duration_minutes: number;
  selected_days: number[];
  weeks: number;
}

export interface BackgroundGenerationResponse {
  success: boolean;
  message: string;
  status: string;
}

export interface GenerationStatusResponse {
  user_id: string;
  status: 'none' | 'pending' | 'in_progress' | 'completed' | 'failed';
  total_expected: number;
  total_generated: number;
  error_message: string | null;
}

export interface EnsureWorkoutsResponse {
  success: boolean;
  message: string;
  workout_count: number;
  needs_generation: boolean;
  status?: string;
}

export const scheduleBackgroundGeneration = async (
  request: ScheduleBackgroundGenerationRequest
): Promise<BackgroundGenerationResponse> => {
  const { data } = await api.post<BackgroundGenerationResponse>(
    '/workouts-db/schedule-background-generation',
    request
  );
  return data;
};

export const getGenerationStatus = async (userId: string): Promise<GenerationStatusResponse> => {
  const { data } = await api.get<GenerationStatusResponse>(
    `/workouts-db/generation-status/${userId}`
  );
  return data;
};

export const ensureWorkoutsGenerated = async (
  request: ScheduleBackgroundGenerationRequest
): Promise<EnsureWorkoutsResponse> => {
  const { data } = await api.post<EnsureWorkoutsResponse>(
    '/workouts-db/ensure-workouts-generated',
    request
  );
  return data;
};

export const completeWorkout = async (workoutId: string): Promise<Workout> => {
  const { data } = await api.post<WorkoutBackend>(`/workouts-db/${workoutId}/complete`);
  return parseWorkout(data);
};

export const deleteWorkout = async (workoutId: string): Promise<void> => {
  await api.delete(`/workouts-db/${workoutId}`);
};

export const swapWorkout = async (params: {
  workout_id: string;
  new_date: string;
  reason?: string;
}): Promise<{ success: boolean; old_date: string; new_date: string; swapped_with?: string }> => {
  const { data } = await api.post('/workouts-db/swap', params);
  return data;
};

// Regenerate workout - uses SCD2 versioning to preserve history
export interface RegenerateWorkoutRequest {
  workout_id: string;
  user_id: string;
  scheduled_date: string;
  duration_minutes?: number;
  equipment?: string[];
  difficulty?: string;  // 'easy', 'medium', 'hard'
  focus_areas?: string[];
}

export const regenerateWorkout = async (request: RegenerateWorkoutRequest): Promise<Workout> => {
  // Map frontend difficulty to backend fitness_level for RAG selection
  const difficultyToFitnessLevel: Record<string, string> = {
    'easy': 'beginner',
    'medium': 'intermediate',
    'hard': 'advanced',
  };
  const fitnessLevel = request.difficulty
    ? difficultyToFitnessLevel[request.difficulty] || 'intermediate'
    : undefined;

  // Use the new versioned regenerate endpoint
  // Send both fitness_level (for RAG) and difficulty (for workout display)
  const regenerateRequest = {
    workout_id: request.workout_id,
    user_id: request.user_id,
    duration_minutes: request.duration_minutes || 45,
    fitness_level: fitnessLevel,
    difficulty: request.difficulty,  // Send explicit difficulty for workout metadata
    equipment: request.equipment,
    focus_areas: request.focus_areas,
  };

  console.log('Regenerating workout with:', regenerateRequest);
  const { data } = await api.post<WorkoutBackend>('/workouts-db/regenerate', regenerateRequest);
  return parseWorkout(data);
};

// ============================================
// Workout Version History (SCD2)
// ============================================

export interface WorkoutVersionInfo {
  id: string;
  version_number: number;
  name: string;
  is_current: boolean;
  valid_from: string | null;
  valid_to: string | null;
  generation_method: string | null;
  exercises_count: number;
}

export interface RevertWorkoutRequest {
  workout_id: string;
  target_version: number;
}

/**
 * Get all versions of a workout (version history).
 * Returns versions ordered by version number (newest first).
 */
export const getWorkoutVersions = async (workoutId: string): Promise<WorkoutVersionInfo[]> => {
  const { data } = await api.get<WorkoutVersionInfo[]>(`/workouts-db/${workoutId}/versions`);
  return data;
};

/**
 * Revert a workout to a previous version.
 * This creates a NEW version with the content of the target version,
 * preserving the full history (SCD2 style).
 */
export const revertWorkout = async (request: RevertWorkoutRequest): Promise<Workout> => {
  const { data } = await api.post<WorkoutBackend>('/workouts-db/revert', request);
  return parseWorkout(data);
};

// ============================================
// Warmups & Stretches
// ============================================

export interface WarmupExercise {
  name: string;
  sets: number;
  reps: number;
  duration_seconds: number;
  rest_seconds: number;
  equipment: string;
  muscle_group: string;
  notes?: string;
}

export interface WarmupResponse {
  id: string;
  workout_id: string;
  exercises_json: WarmupExercise[];
  duration_minutes: number;
  created_at: string;
}

export interface StretchResponse {
  id: string;
  workout_id: string;
  exercises_json: WarmupExercise[];
  duration_minutes: number;
  created_at: string;
}

/**
 * Response type for AI workout summary
 */
export interface WorkoutSummaryResponse {
  summary: string;
}

/**
 * Get AI-generated summary/description for a workout
 */
export const getWorkoutAISummary = async (workoutId: string): Promise<string | null> => {
  try {
    const { data } = await api.get<WorkoutSummaryResponse>(`/workouts-db/${workoutId}/summary`);
    return data.summary;
  } catch {
    return null;
  }
};

/**
 * Get warmup exercises for a workout
 */
export const getWorkoutWarmup = async (workoutId: string): Promise<WarmupResponse | null> => {
  try {
    const { data } = await api.get<WarmupResponse>(`/workouts-db/${workoutId}/warmup`);
    return data;
  } catch {
    return null;
  }
};

/**
 * Get cool-down stretches for a workout
 */
export const getWorkoutStretches = async (workoutId: string): Promise<StretchResponse | null> => {
  try {
    const { data } = await api.get<StretchResponse>(`/workouts-db/${workoutId}/stretches`);
    return data;
  } catch {
    return null;
  }
};

/**
 * Generate and create warmup for an existing workout
 */
export const createWorkoutWarmup = async (
  workoutId: string,
  durationMinutes: number = 5
): Promise<WarmupResponse | null> => {
  try {
    const { data } = await api.post<WarmupResponse>(
      `/workouts-db/${workoutId}/warmup?duration_minutes=${durationMinutes}`
    );
    return data;
  } catch {
    return null;
  }
};

/**
 * Generate and create stretches for an existing workout
 */
export const createWorkoutStretches = async (
  workoutId: string,
  durationMinutes: number = 5
): Promise<StretchResponse | null> => {
  try {
    const { data } = await api.post<StretchResponse>(
      `/workouts-db/${workoutId}/stretches?duration_minutes=${durationMinutes}`
    );
    return data;
  } catch {
    return null;
  }
};

/**
 * Generate and create both warmup and stretches for a workout
 */
export const createWorkoutWarmupAndStretches = async (
  workoutId: string,
  warmupDuration: number = 5,
  stretchDuration: number = 5
): Promise<{ warmup: WarmupResponse | null; stretches: StretchResponse | null }> => {
  try {
    const { data } = await api.post<{ warmup: WarmupResponse | null; stretches: StretchResponse | null }>(
      `/workouts-db/${workoutId}/warmup-and-stretches?warmup_duration=${warmupDuration}&stretch_duration=${stretchDuration}`
    );
    return data;
  } catch {
    return { warmup: null, stretches: null };
  }
};

// Exercises
export const getExercises = async (): Promise<Exercise[]> => {
  const { data } = await api.get('/exercises/');
  return data;
};

export const getExercise = async (exerciseId: string): Promise<Exercise> => {
  const { data } = await api.get(`/exercises/${exerciseId}`);
  return data;
};

export const searchExercises = async (
  query?: string,
  muscleGroups?: string[],
  equipment?: string[]
): Promise<Exercise[]> => {
  const params = new URLSearchParams();
  if (query) params.append('query', query);
  if (muscleGroups) muscleGroups.forEach((m) => params.append('muscle_groups', m));
  if (equipment) equipment.forEach((e) => params.append('equipment', e));
  const { data } = await api.get(`/exercises/search?${params.toString()}`);
  return data;
};

// Exercise Library - Get full exercise details by name
export interface ExerciseLibraryDetails {
  id: number;
  name: string;
  instructions: string | null;
  muscle_group: string | null;
  equipment: string | null;
  video_url: string | null;
}

export const getExerciseFromLibraryByName = async (name: string): Promise<ExerciseLibraryDetails | null> => {
  try {
    const { data } = await api.get<ExerciseLibraryDetails>(`/exercises/library/by-name/${encodeURIComponent(name)}`);
    return data;
  } catch {
    return null;
  }
};

// Chat
export const sendChatMessage = async (request: ChatRequest): Promise<ChatResponse> => {
  // Log if sending with image (truncate image for logging)
  if (request.image_base64) {
    log.info('Sending chat with image', { size_kb: Math.round(request.image_base64.length / 1024) });
  }
  const { data } = await api.post('/chat/send', request, {
    timeout: 60000, // 60 second timeout for image processing
  });
  return data;
};

export const getChatHistory = async (userId: number, limit: number = 100): Promise<ChatHistoryItem[]> => {
  const { data } = await api.get<ChatHistoryItem[]>(`/chat/history/${userId}?limit=${limit}`);
  return data;
};

// Performance
export const logPerformance = async (log: Omit<PerformanceLog, 'id' | 'logged_at'>): Promise<PerformanceLog> => {
  const { data } = await api.post('/performance/log', log);
  return data;
};

export const getPerformanceStats = async (userId: number): Promise<PerformanceStats> => {
  const { data } = await api.get(`/performance/stats/${userId}`);
  return data;
};

export const getPerformanceHistory = async (
  userId: number,
  exerciseId?: string
): Promise<PerformanceLog[]> => {
  const params = exerciseId ? `?exercise_id=${exerciseId}` : '';
  const { data } = await api.get(`/performance/history/${userId}${params}`);
  return data;
};

// Health Metrics
export const calculateHealthMetrics = async (input: MetricsInput): Promise<HealthMetrics> => {
  const { data } = await api.post('/metrics/calculate', {
    user_id: input.userId,
    weight_kg: input.weightKg,
    height_cm: input.heightCm,
    age: input.age,
    gender: input.gender,
    activity_level: input.activityLevel,
    target_weight_kg: input.targetWeightKg,
    waist_cm: input.waistCm,
    hip_cm: input.hipCm,
    neck_cm: input.neckCm,
    body_fat_percent: input.bodyFatPercent,
  });
  return {
    bmi: data.bmi,
    bmiCategory: data.bmi_category,
    targetBmi: data.target_bmi,
    idealBodyWeightDevine: data.ideal_body_weight_devine,
    idealBodyWeightRobinson: data.ideal_body_weight_robinson,
    idealBodyWeightMiller: data.ideal_body_weight_miller,
    bmrMifflin: data.bmr_mifflin,
    bmrHarris: data.bmr_harris,
    tdee: data.tdee,
    waistToHeightRatio: data.waist_to_height_ratio,
    waistToHipRatio: data.waist_to_hip_ratio,
    bodyFatNavy: data.body_fat_navy,
    leanBodyMass: data.lean_body_mass,
    ffmi: data.ffmi,
  };
};

// Active Injuries
export const getActiveInjuries = async (userId: number): Promise<ActiveInjury[]> => {
  const { data } = await api.get(`/metrics/injuries/active/${userId}`);
  return data.injuries?.map((injury: Record<string, unknown>) => ({
    id: injury.id,
    bodyPart: injury.body_part,
    severity: injury.severity,
    reportedAt: injury.reported_at,
    expectedRecoveryDate: injury.expected_recovery_date,
    currentPhase: injury.current_phase,
    phaseDescription: injury.phase_description,
    allowedIntensity: injury.allowed_intensity,
    daysSinceInjury: injury.days_since_injury,
    daysRemaining: injury.days_remaining,
    progressPercent: injury.progress_percent,
    painLevel: injury.pain_level,
    rehabExercises: injury.rehab_exercises || [],
  })) || [];
};

// Conversational Onboarding
export interface ParseOnboardingRequest {
  user_id: string;
  message: string;
  current_data: Record<string, any>;
  conversation_history?: Array<{ role: string; content: string }>;
}

export interface ParseOnboardingResponse {
  extracted_data: Record<string, any>;
  next_question: {
    question: string | null;
    type: string;
    field_target?: string;
    quick_replies?: Array<{ label: string; value: any; icon?: string }>;
    multi_select?: boolean;
    component?: string;
    complete?: boolean;
  };
  is_complete: boolean;
  missing_fields: string[];
}

export interface SaveConversationRequest {
  user_id: string;
  conversation: Array<{
    role: string;
    content: string;
    timestamp: string;
    extracted_data?: Record<string, any>;
  }>;
}

export const parseOnboardingResponse = async (request: ParseOnboardingRequest): Promise<ParseOnboardingResponse> => {
  const { data } = await api.post('/onboarding/parse-response', request);
  return data;
};

export const saveOnboardingConversation = async (request: SaveConversationRequest): Promise<{ success: boolean; message: string }> => {
  const { data } = await api.post('/onboarding/save-conversation', request);
  return data;
};

// ============================================
// Workout Logs (records completed workout sessions)
// ============================================

export const createWorkoutLog = async (data: WorkoutLogCreate): Promise<WorkoutLog> => {
  const { data: response } = await api.post<WorkoutLog>('/performance-db/workout-logs', data);
  return response;
};

export const getWorkoutLogs = async (userId: string): Promise<WorkoutLog[]> => {
  const { data } = await api.get<WorkoutLog[]>(`/performance-db/workout-logs?user_id=${userId}`);
  return data;
};

// ============================================
// Performance Logs (individual set data)
// ============================================

export const createPerformanceLog = async (data: PerformanceLogCreate): Promise<PerformanceLogDetailed> => {
  const { data: response } = await api.post<PerformanceLogDetailed>('/performance-db/logs', data);
  return response;
};

export const getPerformanceLogs = async (
  userId: string,
  exerciseId?: string
): Promise<PerformanceLogDetailed[]> => {
  const params = new URLSearchParams();
  params.append('user_id', userId);
  if (exerciseId) params.append('exercise_id', exerciseId);
  const { data } = await api.get<PerformanceLogDetailed[]>(`/performance-db/logs?${params.toString()}`);
  return data;
};

export const getExerciseHistory = async (
  userId: string,
  exerciseId: string,
  limit: number = 5
): Promise<PerformanceLogDetailed[]> => {
  const { data } = await api.get<PerformanceLogDetailed[]>(
    `/performance-db/logs?user_id=${userId}&exercise_id=${exerciseId}&limit=${limit}`
  );
  return data;
};

// ============================================
// Strength Records (Personal Records / PRs)
// ============================================

export const getStrengthRecords = async (
  userId: string,
  exerciseId?: string,
  prsOnly: boolean = false
): Promise<StrengthRecord[]> => {
  const params = new URLSearchParams();
  params.append('user_id', userId);
  if (exerciseId) params.append('exercise_id', exerciseId);
  if (prsOnly) params.append('prs_only', 'true');
  const { data } = await api.get<StrengthRecord[]>(`/performance-db/strength-records?${params.toString()}`);
  return data;
};

export const createStrengthRecord = async (data: StrengthRecordCreate): Promise<StrengthRecord> => {
  const { data: response } = await api.post<StrengthRecord>('/performance-db/strength-records', data);
  return response;
};

// ============================================
// Weekly Volume Tracking
// ============================================

export const getWeeklyVolumes = async (
  userId: string,
  week?: number,
  year?: number
): Promise<WeeklyVolume[]> => {
  const params = new URLSearchParams();
  params.append('user_id', userId);
  if (week !== undefined) params.append('week_number', week.toString());
  if (year !== undefined) params.append('year', year.toString());
  const { data } = await api.get<WeeklyVolume[]>(`/performance-db/weekly-volume?${params.toString()}`);
  return data;
};

export const updateWeeklyVolume = async (
  userId: string,
  muscleGroup: string,
  weekNumber: number,
  year: number,
  sets: number,
  reps: number,
  volumeKg: number
): Promise<WeeklyVolume> => {
  const { data } = await api.post<WeeklyVolume>('/performance-db/weekly-volume', {
    user_id: userId,
    muscle_group: muscleGroup,
    week_number: weekNumber,
    year: year,
    total_sets: sets,
    total_reps: reps,
    total_volume_kg: volumeKg,
    frequency: 1,
    recovery_status: 'optimal',
  });
  return data;
};

// ============================================
// Exercise Videos
// ============================================

export interface VideoResponse {
  url: string;
  expires_in: number;
  exercise_name: string;
  current_gender: 'male' | 'female' | null;
  has_male: boolean;
  has_female: boolean;
}

export const getExerciseVideoInfo = async (
  exerciseName: string,
  gender?: 'male' | 'female'
): Promise<VideoResponse | null> => {
  try {
    const params = gender ? `?gender=${gender}` : '';
    const { data } = await api.get<VideoResponse>(
      `/videos/by-exercise/${encodeURIComponent(exerciseName)}${params}`
    );
    return data;
  } catch {
    return null;
  }
};

// Backwards compatible function that just returns the URL
export const getExerciseVideoUrl = async (exerciseName: string): Promise<string | null> => {
  const info = await getExerciseVideoInfo(exerciseName);
  return info?.url ?? null;
};

// ============================================
// Email Reminders
// ============================================

export interface TestEmailResponse {
  success: boolean;
  message: string;
  email_id?: string;
}

export const sendTestEmail = async (email: string): Promise<TestEmailResponse> => {
  const { data } = await api.post<TestEmailResponse>(`/reminders/test?to_email=${encodeURIComponent(email)}`);
  return data;
};

// ============================================
// Notification Settings
// ============================================

export interface NotificationSettingsPayload {
  emailEnabled: boolean;
  pushEnabled: boolean;
  workoutReminderFrequency: 'none' | 'workout_days' | 'daily';
  summaryEmailFrequencies: Array<'weekly' | 'monthly' | '3_months' | '6_months' | '12_months'>;
  includedInSummary: {
    workoutData: boolean;
    weightData: boolean;
  };
  foodTrackingEnabled: boolean;
  foodTrackingMeals: {
    breakfast: boolean;
    lunch: boolean;
    dinner: boolean;
  };
  motivationEmailsEnabled: boolean;
}

export const saveNotificationSettings = async (
  userId: string,
  settings: NotificationSettingsPayload
): Promise<{ success: boolean }> => {
  await api.patch(`/users/${userId}`, {
    preferences: JSON.stringify({
      notifications: settings,
    }),
  });
  return { success: true };
};

// ============================================
// Nutrition Tracking
// ============================================

export interface FoodLogResponse {
  id: string;
  user_id: string;
  meal_type: string;
  logged_at: string;
  food_items: Array<{
    name: string;
    amount?: string;
    calories?: number;
    protein_g?: number;
    carbs_g?: number;
    fat_g?: number;
  }>;
  total_calories: number;
  protein_g: number;
  carbs_g: number;
  fat_g: number;
  fiber_g?: number;
  health_score?: number;
  ai_feedback?: string;
  created_at: string;
}

export interface DailyNutritionResponse {
  date: string;
  total_calories: number;
  total_protein_g: number;
  total_carbs_g: number;
  total_fat_g: number;
  total_fiber_g: number;
  meal_count: number;
  avg_health_score?: number;
  meals: FoodLogResponse[];
}

export interface WeeklyNutritionResponse {
  start_date: string;
  end_date: string;
  daily_summaries: Array<{
    date: string;
    total_calories: number;
    total_protein_g: number;
    total_carbs_g: number;
    total_fat_g: number;
    meal_count: number;
  }>;
  total_calories: number;
  average_daily_calories: number;
  total_meals: number;
}

export interface NutritionTargetsResponse {
  user_id: string;
  daily_calorie_target?: number;
  daily_protein_target_g?: number;
  daily_carbs_target_g?: number;
  daily_fat_target_g?: number;
}

export const getFoodLogs = async (
  userId: string,
  options?: {
    limit?: number;
    from_date?: string;
    to_date?: string;
    meal_type?: string;
  }
): Promise<FoodLogResponse[]> => {
  const params = new URLSearchParams();
  if (options?.limit) params.append('limit', options.limit.toString());
  if (options?.from_date) params.append('from_date', options.from_date);
  if (options?.to_date) params.append('to_date', options.to_date);
  if (options?.meal_type) params.append('meal_type', options.meal_type);
  const { data } = await api.get<FoodLogResponse[]>(`/nutrition/food-logs/${userId}?${params.toString()}`);
  return data;
};

export const getDailyNutritionSummary = async (
  userId: string,
  date?: string
): Promise<DailyNutritionResponse> => {
  const params = date ? `?date=${date}` : '';
  const { data } = await api.get<DailyNutritionResponse>(`/nutrition/summary/daily/${userId}${params}`);
  return data;
};

export const getWeeklyNutritionSummary = async (
  userId: string,
  startDate?: string
): Promise<WeeklyNutritionResponse> => {
  const params = startDate ? `?start_date=${startDate}` : '';
  const { data } = await api.get<WeeklyNutritionResponse>(`/nutrition/summary/weekly/${userId}${params}`);
  return data;
};

export const getNutritionTargets = async (userId: string): Promise<NutritionTargetsResponse> => {
  const { data } = await api.get<NutritionTargetsResponse>(`/nutrition/targets/${userId}`);
  return data;
};

export const updateNutritionTargets = async (
  userId: string,
  targets: {
    daily_calorie_target?: number;
    daily_protein_target_g?: number;
    daily_carbs_target_g?: number;
    daily_fat_target_g?: number;
  }
): Promise<NutritionTargetsResponse> => {
  const { data } = await api.put<NutritionTargetsResponse>(`/nutrition/targets/${userId}`, {
    user_id: userId,
    ...targets,
  });
  return data;
};

export const deleteFoodLog = async (logId: string): Promise<void> => {
  await api.delete(`/nutrition/food-logs/${logId}`);
};

export default api;
