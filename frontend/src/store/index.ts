import { create } from 'zustand';
import { persist } from 'zustand/middleware';
import type { User, Workout, ChatMessage, OnboardingData } from '../types';

interface AppState {
  // User state
  user: User | null;
  setUser: (user: User | null) => void;

  // Current workout
  currentWorkout: Workout | null;
  setCurrentWorkout: (workout: Workout | null) => void;

  // Workouts list
  workouts: Workout[];
  setWorkouts: (workouts: Workout[]) => void;
  addWorkout: (workout: Workout) => void;
  removeWorkout: (workoutId: number) => void;

  // Chat history
  chatHistory: ChatMessage[];
  addChatMessage: (message: ChatMessage) => void;
  clearChatHistory: () => void;

  // Onboarding
  onboardingData: OnboardingData;
  setOnboardingData: (data: Partial<OnboardingData>) => void;
  resetOnboarding: () => void;

  // Active workout session
  activeWorkoutId: number | null;
  setActiveWorkoutId: (id: number | null) => void;
  exerciseProgress: Record<string, boolean>;
  setExerciseComplete: (exerciseId: string, complete: boolean) => void;
  resetExerciseProgress: () => void;
}

const defaultOnboarding: OnboardingData = {
  // Screen 1: Personal Info
  name: '',
  gender: 'prefer_not_to_say',
  age: 30,

  // Screen 2: Body Metrics
  heightCm: 170,
  weightKg: 70,
  targetWeightKg: undefined,

  // Screen 3: Fitness Background
  fitnessLevel: 'beginner',
  goals: [],
  workoutExperience: [],

  // Screen 4: Schedule
  daysPerWeek: 4,
  selectedDays: [0, 1, 3, 4],  // Mon, Tue, Thu, Fri default
  preferredTime: 'morning',
  workoutDuration: 45,

  // Screen 5: Workout Preferences
  trainingSplit: 'full_body',
  intensityPreference: 'moderate',
  equipment: [],
  workoutVariety: 'varied',

  // Screen 6: Health & Limitations
  activeInjuries: [],
  healthConditions: [],
  activityLevel: 'lightly_active',
};

const STORAGE_VERSION = 3;

export const useAppStore = create<AppState>()(
  persist(
    (set) => ({
      // User
      user: null,
      setUser: (user) => set({ user }),

      // Current workout
      currentWorkout: null,
      setCurrentWorkout: (workout) => set({ currentWorkout: workout }),

      // Workouts
      workouts: [],
      setWorkouts: (workouts) => set({ workouts }),
      addWorkout: (workout) => set((state) => ({ workouts: [...state.workouts, workout] })),
      removeWorkout: (workoutId) =>
        set((state) => ({
          workouts: state.workouts.filter((w) => w.id !== workoutId),
        })),

      // Chat
      chatHistory: [],
      addChatMessage: (message) =>
        set((state) => ({
          chatHistory: [...state.chatHistory, message],
        })),
      clearChatHistory: () => set({ chatHistory: [] }),

      // Onboarding
      onboardingData: defaultOnboarding,
      setOnboardingData: (data) =>
        set((state) => ({
          onboardingData: { ...state.onboardingData, ...data },
        })),
      resetOnboarding: () => set({ onboardingData: defaultOnboarding }),

      // Active workout
      activeWorkoutId: null,
      setActiveWorkoutId: (id) => set({ activeWorkoutId: id }),
      exerciseProgress: {},
      setExerciseComplete: (exerciseId, complete) =>
        set((state) => ({
          exerciseProgress: { ...state.exerciseProgress, [exerciseId]: complete },
        })),
      resetExerciseProgress: () => set({ exerciseProgress: {} }),
    }),
    {
      name: 'fitness-coach-storage',
      version: STORAGE_VERSION,
      partialize: (state) => ({
        user: state.user,
        onboardingData: state.onboardingData,
      }),
      migrate: (persistedState, version) => {
        // Clear old data if version mismatch
        if (version < STORAGE_VERSION) {
          return { user: null, onboardingData: defaultOnboarding };
        }
        return persistedState as { user: User | null; onboardingData: OnboardingData };
      },
    }
  )
);

// Helper to clear storage and reset app
export const clearAppStorage = () => {
  localStorage.removeItem('fitness-coach-storage');
  useAppStore.setState({
    user: null,
    onboardingData: defaultOnboarding,
    workouts: [],
    chatHistory: [],
    currentWorkout: null,
    activeWorkoutId: null,
    exerciseProgress: {},
  });
};
