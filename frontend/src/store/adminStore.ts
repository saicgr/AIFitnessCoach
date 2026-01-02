import { create } from 'zustand';
import { persist } from 'zustand/middleware';

// ============================================
// Admin Types
// ============================================

export interface AdminUser {
  id: string;
  email: string;
  name: string;
  role: 'admin' | 'support_agent' | 'super_admin';
  avatar_url?: string;
  created_at: string;
}

export interface AdminSession {
  token: string;
  user: AdminUser;
  expires_at: string;
}

export interface LiveChatUser {
  id: string;
  name: string;
  email?: string;
  avatar_url?: string;
  fitness_level?: string;
  goals?: string[];
  subscription_tier?: string;
}

export interface LiveChatMessage {
  id: string;
  chat_id: string;
  sender_type: 'user' | 'admin' | 'ai';
  sender_id: string;
  sender_name: string;
  content: string;
  created_at: string;
  read_at?: string;
}

export interface LiveChat {
  id: string;
  user: LiveChatUser;
  category: 'general' | 'technical' | 'billing' | 'workout' | 'nutrition';
  status: 'waiting' | 'active' | 'resolved' | 'escalated';
  priority: 'low' | 'normal' | 'high' | 'urgent';
  assigned_agent_id?: string;
  assigned_agent_name?: string;
  created_at: string;
  updated_at: string;
  last_message_at: string;
  unread_count: number;
  messages: LiveChatMessage[];
  ai_handoff_context?: {
    reason: string;
    conversation_summary: string;
    user_sentiment: string;
    suggested_response?: string;
  };
}

export interface DashboardStats {
  active_chats: number;
  queue_size: number;
  avg_wait_time_seconds: number;
  online_agents: number;
  resolved_today: number;
  avg_resolution_time_seconds: number;
  satisfaction_score: number;
  escalation_rate: number;
}

export interface RecentActivity {
  id: string;
  type: 'chat_started' | 'chat_resolved' | 'escalation' | 'agent_joined' | 'agent_left';
  description: string;
  actor_name: string;
  timestamp: string;
}

// ============================================
// Admin Store State
// ============================================

interface AdminState {
  // Session
  session: AdminSession | null;
  isAuthenticated: boolean;
  setSession: (session: AdminSession | null) => void;
  logout: () => void;

  // Dashboard Stats
  stats: DashboardStats | null;
  setStats: (stats: DashboardStats | null) => void;

  // Recent Activity
  recentActivity: RecentActivity[];
  setRecentActivity: (activity: RecentActivity[]) => void;

  // Active Chats
  activeChats: LiveChat[];
  setActiveChats: (chats: LiveChat[]) => void;
  addChat: (chat: LiveChat) => void;
  updateChat: (chatId: string, updates: Partial<LiveChat>) => void;
  removeChat: (chatId: string) => void;

  // Selected Chat
  selectedChatId: string | null;
  setSelectedChatId: (chatId: string | null) => void;
  selectedChat: LiveChat | null;

  // Chat Messages
  addMessage: (chatId: string, message: LiveChatMessage) => void;
  markMessagesAsRead: (chatId: string) => void;

  // Notification Settings
  notificationsEnabled: boolean;
  soundEnabled: boolean;
  setNotificationsEnabled: (enabled: boolean) => void;
  setSoundEnabled: (enabled: boolean) => void;

  // UI State
  sidebarCollapsed: boolean;
  setSidebarCollapsed: (collapsed: boolean) => void;
}

// ============================================
// Admin Store Implementation
// ============================================

export const useAdminStore = create<AdminState>()(
  persist(
    (set, get) => ({
      // Session
      session: null,
      isAuthenticated: false,
      setSession: (session) =>
        set({
          session,
          isAuthenticated: !!session,
        }),
      logout: () =>
        set({
          session: null,
          isAuthenticated: false,
          activeChats: [],
          selectedChatId: null,
          stats: null,
          recentActivity: [],
        }),

      // Dashboard Stats
      stats: null,
      setStats: (stats) => set({ stats }),

      // Recent Activity
      recentActivity: [],
      setRecentActivity: (activity) => set({ recentActivity: activity }),

      // Active Chats
      activeChats: [],
      setActiveChats: (chats) => set({ activeChats: chats }),
      addChat: (chat) =>
        set((state) => ({
          activeChats: [chat, ...state.activeChats],
        })),
      updateChat: (chatId, updates) =>
        set((state) => ({
          activeChats: state.activeChats.map((chat) =>
            chat.id === chatId ? { ...chat, ...updates } : chat
          ),
        })),
      removeChat: (chatId) =>
        set((state) => ({
          activeChats: state.activeChats.filter((chat) => chat.id !== chatId),
          selectedChatId: state.selectedChatId === chatId ? null : state.selectedChatId,
        })),

      // Selected Chat
      selectedChatId: null,
      setSelectedChatId: (chatId) => set({ selectedChatId: chatId }),
      get selectedChat() {
        const state = get();
        return state.activeChats.find((chat) => chat.id === state.selectedChatId) || null;
      },

      // Chat Messages
      addMessage: (chatId, message) =>
        set((state) => ({
          activeChats: state.activeChats.map((chat) =>
            chat.id === chatId
              ? {
                  ...chat,
                  messages: [...chat.messages, message],
                  last_message_at: message.created_at,
                  unread_count:
                    message.sender_type === 'user' && state.selectedChatId !== chatId
                      ? chat.unread_count + 1
                      : chat.unread_count,
                }
              : chat
          ),
        })),
      markMessagesAsRead: (chatId) =>
        set((state) => ({
          activeChats: state.activeChats.map((chat) =>
            chat.id === chatId ? { ...chat, unread_count: 0 } : chat
          ),
        })),

      // Notification Settings
      notificationsEnabled: true,
      soundEnabled: true,
      setNotificationsEnabled: (enabled) => set({ notificationsEnabled: enabled }),
      setSoundEnabled: (enabled) => set({ soundEnabled: enabled }),

      // UI State
      sidebarCollapsed: false,
      setSidebarCollapsed: (collapsed) => set({ sidebarCollapsed: collapsed }),
    }),
    {
      name: 'admin-storage',
      partialize: (state) => ({
        session: state.session,
        isAuthenticated: state.isAuthenticated,
        notificationsEnabled: state.notificationsEnabled,
        soundEnabled: state.soundEnabled,
        sidebarCollapsed: state.sidebarCollapsed,
      }),
    }
  )
);

// ============================================
// Helper Functions
// ============================================

export const formatWaitTime = (seconds: number): string => {
  if (seconds < 60) {
    return `${seconds}s`;
  } else if (seconds < 3600) {
    const minutes = Math.floor(seconds / 60);
    return `${minutes}m`;
  } else {
    const hours = Math.floor(seconds / 3600);
    const minutes = Math.floor((seconds % 3600) / 60);
    return `${hours}h ${minutes}m`;
  }
};

export const getCategoryColor = (category: LiveChat['category']): string => {
  const colors = {
    general: 'bg-blue-500/20 text-blue-400',
    technical: 'bg-orange-500/20 text-orange-400',
    billing: 'bg-green-500/20 text-green-400',
    workout: 'bg-purple-500/20 text-purple-400',
    nutrition: 'bg-pink-500/20 text-pink-400',
  };
  return colors[category] || colors.general;
};

export const getPriorityColor = (priority: LiveChat['priority']): string => {
  const colors = {
    low: 'text-gray-400',
    normal: 'text-blue-400',
    high: 'text-orange-400',
    urgent: 'text-red-400',
  };
  return colors[priority] || colors.normal;
};

export const getStatusColor = (status: LiveChat['status']): string => {
  const colors = {
    waiting: 'bg-yellow-500/20 text-yellow-400',
    active: 'bg-green-500/20 text-green-400',
    resolved: 'bg-gray-500/20 text-gray-400',
    escalated: 'bg-red-500/20 text-red-400',
  };
  return colors[status] || colors.waiting;
};
