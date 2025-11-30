import { create } from 'zustand';
import { persist } from 'zustand/middleware';
import type { Session } from '@supabase/supabase-js';
import type { User, Workout, ChatMessage, OnboardingData } from '../types';

interface AppState {
  // Theme state
  theme: 'dark' | 'light';
  setTheme: (theme: 'dark' | 'light') => void;
  toggleTheme: () => void;

  // Auth state
  session: Session | null;
  setSession: (session: Session | null) => void;

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
  setChatHistory: (messages: ChatMessage[]) => void;
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

  // Screen 2b: Advanced Body Measurements (collapsible/optional)
  waistCircumferenceCm: undefined,
  hipCircumferenceCm: undefined,
  neckCircumferenceCm: undefined,
  bodyFatPercent: undefined,
  restingHeartRate: undefined,
  bloodPressureSystolic: undefined,
  bloodPressureDiastolic: undefined,

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

const STORAGE_VERSION = 4;

// Helper to apply theme class to document
const applyThemeToDocument = (theme: 'dark' | 'light') => {
  if (typeof document !== 'undefined') {
    if (theme === 'light') {
      document.documentElement.classList.add('light-mode');
    } else {
      document.documentElement.classList.remove('light-mode');
    }
  }
};

export const useAppStore = create<AppState>()(
  persist(
    (set) => ({
      // Theme
      theme: 'dark',
      setTheme: (theme) => {
        applyThemeToDocument(theme);
        set({ theme });
      },
      toggleTheme: () =>
        set((state) => {
          const newTheme = state.theme === 'dark' ? 'light' : 'dark';
          applyThemeToDocument(newTheme);
          return { theme: newTheme };
        }),

      // Auth
      session: null,
      setSession: (session) => set({ session }),

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
      setChatHistory: (messages) => set({ chatHistory: messages }),
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
        session: state.session,
        onboardingData: state.onboardingData,
        theme: state.theme,
      }),
      migrate: (persistedState, version) => {
        // Clear old data if version mismatch
        if (version < STORAGE_VERSION) {
          return { user: null, session: null, onboardingData: defaultOnboarding, theme: 'dark' as const };
        }
        return persistedState as { user: User | null; session: Session | null; onboardingData: OnboardingData; theme: 'dark' | 'light' };
      },
      onRehydrateStorage: () => (state) => {
        // Apply theme when store rehydrates from localStorage
        if (state?.theme) {
          applyThemeToDocument(state.theme);
        }
      },
    }
  )
);

// Helper to clear storage and reset app
export const clearAppStorage = () => {
  localStorage.removeItem('fitness-coach-storage');
  useAppStore.setState({
    theme: 'dark',
    session: null,
    user: null,
    onboardingData: defaultOnboarding,
    workouts: [],
    chatHistory: [],
    currentWorkout: null,
    activeWorkoutId: null,
    exerciseProgress: {},
  });
  applyThemeToDocument('dark');
};
