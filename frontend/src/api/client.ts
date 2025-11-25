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
  Exercise,
  PerformanceLog,
  PerformanceStats,
  HealthResponse,
} from '../types';
import { parseUser, parseWorkout } from '../types';
import { createLogger } from '../utils/logger';

const log = createLogger('api');

const api = axios.create({
  baseURL: '/api/v1',
  headers: {
    'Content-Type': 'application/json',
  },
});

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

// Users
export const createUser = async (user: CreateUserRequest): Promise<User> => {
  const { data } = await api.post<UserBackend>('/users/', user);
  return parseUser(data);
};

export const getUser = async (userId: number): Promise<User> => {
  const { data } = await api.get<UserBackend>(`/users/${userId}`);
  return parseUser(data);
};

export const updateUser = async (userId: number, updates: UpdateUserRequest): Promise<User> => {
  const { data } = await api.patch<UserBackend>(`/users/${userId}`, updates);
  return parseUser(data);
};

export const resetUser = async (userId: number): Promise<void> => {
  await api.delete(`/users/${userId}/reset`);
};

// Workouts
export const getWorkouts = async (userId: number): Promise<Workout[]> => {
  const { data } = await api.get<WorkoutBackend[]>(`/workouts-db/?user_id=${userId}`);
  return data.map(parseWorkout);
};

export const getWorkout = async (workoutId: number): Promise<Workout> => {
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
  const { data } = await api.post<{ workouts: WorkoutBackend[]; total_generated: number }>('/workouts-db/generate-monthly', request);
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

export const completeWorkout = async (workoutId: number): Promise<Workout> => {
  const { data } = await api.post<WorkoutBackend>(`/workouts-db/${workoutId}/complete`);
  return parseWorkout(data);
};

export const deleteWorkout = async (workoutId: number): Promise<void> => {
  await api.delete(`/workouts-db/${workoutId}`);
};

export const swapWorkout = async (params: {
  workout_id: number;
  new_date: string;
  reason?: string;
}): Promise<{ success: boolean; old_date: string; new_date: string; swapped_with?: number }> => {
  const { data } = await api.post('/workouts-db/swap', params);
  return data;
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

// Chat
export const sendChatMessage = async (request: ChatRequest): Promise<ChatResponse> => {
  const { data } = await api.post('/chat/send', request);
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

export default api;
