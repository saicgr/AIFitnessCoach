import { create } from 'zustand';
import { persist } from 'zustand/middleware';
import type { Session } from '@supabase/supabase-js';
import type { User, Workout, ChatMessage, OnboardingData } from '../types';

interface AppState {
  // Theme state
  theme: 'dark' | 'light';
  setTheme: (theme: 'dark' | 'light') => void;
  toggleTheme: () => void;

  // Notification settings
  notificationSettings: {
    // Channel preferences
    emailEnabled: boolean;
    pushEnabled: boolean;

    // Workout reminder frequency
    workoutReminderFrequency: 'none' | 'workout_days' | 'daily';

    // Summary emails - multi-select array
    summaryEmailFrequencies: Array<'weekly' | 'monthly' | '3_months' | '6_months' | '12_months'>;
    includedInSummary: {
      workoutData: boolean;
      weightData: boolean;
    };

    // Food tracking emails
    foodTrackingEnabled: boolean;
    foodTrackingMeals: {
      breakfast: boolean;
      lunch: boolean;
      dinner: boolean;
    };

    // Motivation emails
    motivationEmailsEnabled: boolean;
  };
  setNotificationSettings: (settings: Partial<AppState['notificationSettings']>) => void;
  setIncludedInSummary: (data: Partial<AppState['notificationSettings']['includedInSummary']>) => void;
  setFoodTrackingMeals: (meals: Partial<AppState['notificationSettings']['foodTrackingMeals']>) => void;
  toggleSummaryEmailFrequency: (frequency: 'weekly' | 'monthly' | '3_months' | '6_months' | '12_months') => void;

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
  removeWorkout: (workoutId: string) => void;

  // Chat history
  chatHistory: ChatMessage[];
  setChatHistory: (messages: ChatMessage[]) => void;
  addChatMessage: (message: ChatMessage) => void;
  clearChatHistory: () => void;

  // Onboarding
  onboardingData: OnboardingData;
  setOnboardingData: (data: Partial<OnboardingData>) => void;
  resetOnboarding: () => void;

  // Conversational Onboarding
  conversationalOnboarding: {
    isActive: boolean;
    messages: Array<{
      role: 'user' | 'assistant';
      content: string;
      timestamp: string;
      quickReplies?: Array<{ label: string; value: any; icon?: string }>;
      multiSelect?: boolean;
      component?: 'day_picker' | 'unit_input' | 'health_checklist';
      extractedData?: Partial<OnboardingData>;
    }>;
    collectedData: Partial<OnboardingData>;
    completedFields: string[];
  };
  setConversationalOnboarding: (data: Partial<AppState['conversationalOnboarding']>) => void;
  addConversationalMessage: (message: AppState['conversationalOnboarding']['messages'][0]) => void;
  updateCollectedData: (data: Partial<OnboardingData>) => void;
  resetConversationalOnboarding: () => void;

  // Active workout session
  activeWorkoutId: string | null;
  setActiveWorkoutId: (id: string | null) => void;
  exerciseProgress: Record<string, boolean>;
  setExerciseComplete: (exerciseId: string, complete: boolean) => void;
  resetExerciseProgress: () => void;

  // Chat Widget state
  chatWidgetState: {
    isOpen: boolean;
    sizeMode: 'minimized' | 'medium' | 'maximized';
    hasUnreadMessages: boolean;
  };
  setChatWidgetOpen: (open: boolean) => void;
  setChatWidgetSize: (size: 'minimized' | 'medium' | 'maximized') => void;
  setHasUnreadMessages: (hasUnread: boolean) => void;
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

const STORAGE_VERSION = 6;

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

      // Notifications
      notificationSettings: {
        emailEnabled: true,
        pushEnabled: false,
        workoutReminderFrequency: 'workout_days',
        summaryEmailFrequencies: [],
        includedInSummary: {
          workoutData: true,
          weightData: true,
        },
        foodTrackingEnabled: false,
        foodTrackingMeals: {
          breakfast: true,
          lunch: true,
          dinner: true,
        },
        motivationEmailsEnabled: false,
      },
      setNotificationSettings: (settings) =>
        set((state) => ({
          notificationSettings: { ...state.notificationSettings, ...settings },
        })),
      setIncludedInSummary: (data) =>
        set((state) => ({
          notificationSettings: {
            ...state.notificationSettings,
            includedInSummary: { ...state.notificationSettings.includedInSummary, ...data },
          },
        })),
      setFoodTrackingMeals: (meals) =>
        set((state) => ({
          notificationSettings: {
            ...state.notificationSettings,
            foodTrackingMeals: { ...state.notificationSettings.foodTrackingMeals, ...meals },
          },
        })),
      toggleSummaryEmailFrequency: (frequency) =>
        set((state) => {
          const current = state.notificationSettings.summaryEmailFrequencies || [];
          const updated = current.includes(frequency)
            ? current.filter((f) => f !== frequency)
            : [...current, frequency];
          return {
            notificationSettings: {
              ...state.notificationSettings,
              summaryEmailFrequencies: updated,
            },
          };
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

      // Conversational Onboarding
      conversationalOnboarding: {
        isActive: false,
        messages: [],
        collectedData: {},
        completedFields: [],
      },
      setConversationalOnboarding: (data) =>
        set((state) => ({
          conversationalOnboarding: { ...state.conversationalOnboarding, ...data },
        })),
      addConversationalMessage: (message) =>
        set((state) => ({
          conversationalOnboarding: {
            ...state.conversationalOnboarding,
            messages: [...state.conversationalOnboarding.messages, message],
          },
        })),
      updateCollectedData: (data) =>
        set((state) => ({
          conversationalOnboarding: {
            ...state.conversationalOnboarding,
            collectedData: { ...state.conversationalOnboarding.collectedData, ...data },
          },
        })),
      resetConversationalOnboarding: () =>
        set({
          conversationalOnboarding: {
            isActive: false,
            messages: [],
            collectedData: {},
            completedFields: [],
          },
        }),

      // Active workout
      activeWorkoutId: null,
      setActiveWorkoutId: (id) => set({ activeWorkoutId: id }),
      exerciseProgress: {},
      setExerciseComplete: (exerciseId, complete) =>
        set((state) => ({
          exerciseProgress: { ...state.exerciseProgress, [exerciseId]: complete },
        })),
      resetExerciseProgress: () => set({ exerciseProgress: {} }),

      // Chat Widget
      chatWidgetState: {
        isOpen: false,
        sizeMode: 'medium',
        hasUnreadMessages: false,
      },
      setChatWidgetOpen: (open) =>
        set((state) => ({
          chatWidgetState: { ...state.chatWidgetState, isOpen: open },
        })),
      setChatWidgetSize: (size) =>
        set((state) => ({
          chatWidgetState: { ...state.chatWidgetState, sizeMode: size },
        })),
      setHasUnreadMessages: (hasUnread) =>
        set((state) => ({
          chatWidgetState: { ...state.chatWidgetState, hasUnreadMessages: hasUnread },
        })),
    }),
    {
      name: 'fitness-coach-storage',
      version: STORAGE_VERSION,
      partialize: (state) => ({
        user: state.user,
        session: state.session,
        onboardingData: state.onboardingData,
        theme: state.theme,
        notificationSettings: state.notificationSettings,
      }),
      migrate: (persistedState, version) => {
        // Clear old data if version mismatch
        if (version < STORAGE_VERSION) {
          return {
            user: null,
            session: null,
            onboardingData: defaultOnboarding,
            theme: 'dark' as const,
            notificationSettings: {
              emailEnabled: true,
              pushEnabled: false,
              workoutReminderFrequency: 'workout_days' as const,
              summaryEmailFrequencies: [] as Array<'weekly' | 'monthly' | '3_months' | '6_months' | '12_months'>,
              includedInSummary: { workoutData: true, weightData: true },
              foodTrackingEnabled: false,
              foodTrackingMeals: { breakfast: true, lunch: true, dinner: true },
              motivationEmailsEnabled: false,
            },
          };
        }
        return persistedState as {
          user: User | null;
          session: Session | null;
          onboardingData: OnboardingData;
          theme: 'dark' | 'light';
          notificationSettings: AppState['notificationSettings'];
        };
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
    notificationSettings: {
      emailEnabled: true,
      pushEnabled: false,
      workoutReminderFrequency: 'workout_days',
      summaryEmailFrequencies: [],
      includedInSummary: { workoutData: true, weightData: true },
      foodTrackingEnabled: false,
      foodTrackingMeals: { breakfast: true, lunch: true, dinner: true },
      motivationEmailsEnabled: false,
    },
    session: null,
    user: null,
    onboardingData: defaultOnboarding,
    workouts: [],
    chatHistory: [],
    currentWorkout: null,
    activeWorkoutId: null,
    exerciseProgress: {},
    chatWidgetState: {
      isOpen: false,
      sizeMode: 'medium',
      hasUnreadMessages: false,
    },
  });
  applyThemeToDocument('dark');
};
