/**
 * LiveChatQueue - List of active chats with auto-refresh
 *
 * Features:
 * - List of active chats with user name, category, wait time, unread count
 * - Click to select chat
 * - Auto-refresh every 5 seconds
 * - Browser notification permission request
 * - Sound on new message
 */
import { useEffect, useState, useCallback, useRef } from 'react';
import { useAdminStore, type LiveChat } from '../../store/adminStore';
import { getActiveLiveChats } from '../../api/client';
import { AdminLayout, ChatQueueItem, ChatMessageList, AdminReplyInput } from '../../components/admin';
import { sendAdminReply, resolveLiveChat, claimLiveChat } from '../../api/client';

// Notification sound (base64 encoded simple beep)
const NOTIFICATION_SOUND = 'data:audio/wav;base64,UklGRnoGAABXQVZFZm10IBAAAAABAAEAQB8AAEAfAAABAAgAZGF0YQoGAACBhYqFbF1fdJivrJBhNjVgodDbq2EcBj+a2teleVt+yNrAhkMcPo7G6cSKSTY7j8TqyI1ONkKRxObJjE05P4/D5smPUDpBkMPlyI9QOT+Nwufai1tDXKLP29GKUidIkcbnyIxNNT2LwunIj1E7Q5LD5ciPUDlBkMTlyI5ONj+NwufIj1E6QpHE5siOTjY/jcLnyI5ROUKRxOXIjk43QI3C58iOUDpBkcTlyI5ONUKNQ+fIjlA7QJC95siNTjVBjMLnyI5QOkGPv+bIjU41QYzC58iOUDpBj7/myI5PNkGMwufIjlA7QY/A5siOTzZBi7/nyI5QO0GPv+bIjk82QIu/58iOUDxBj7/myI5PNkCLv+fIjlA8QY+/5siOTzZAi7/nyI5QPUGQv+bIjk82QIu/58iOUD1Bj7/myI5PNkCLv+fIjlA9QY+/5siOTzZAi7/nyI5QPUGPv+bIjk82QIu/58iOUD1Bj7/myI5PNkCLv+fIjlA9QY+/5siOTzZAi7/nyI5QPUGPv+bIjk82';

export default function LiveChatQueue() {
  const {
    activeChats,
    setActiveChats,
    selectedChatId,
    setSelectedChatId,
    session,
    notificationsEnabled,
    soundEnabled,
    setNotificationsEnabled,
    addMessage,
    markMessagesAsRead,
  } = useAdminStore();

  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [filter, setFilter] = useState<'all' | 'waiting' | 'active'>('all');
  const [sending, setSending] = useState(false);
  const [resolving, setResolving] = useState(false);

  const audioRef = useRef<HTMLAudioElement | null>(null);
  const previousChatsRef = useRef<LiveChat[]>([]);

  // Initialize audio
  useEffect(() => {
    audioRef.current = new Audio(NOTIFICATION_SOUND);
  }, []);

  // Request notification permission
  useEffect(() => {
    if (notificationsEnabled && 'Notification' in window && Notification.permission === 'default') {
      Notification.requestPermission();
    }
  }, [notificationsEnabled]);

  // Fetch chats
  const fetchChats = useCallback(async () => {
    try {
      const chats = await getActiveLiveChats(filter === 'all' ? undefined : filter);

      // Check for new messages
      if (previousChatsRef.current.length > 0) {
        chats.forEach((chat) => {
          const prevChat = previousChatsRef.current.find((c) => c.id === chat.id);
          if (prevChat && chat.messages.length > prevChat.messages.length) {
            // New message received
            const newMessage = chat.messages[chat.messages.length - 1];
            if (newMessage.sender_type === 'user') {
              // Play sound
              if (soundEnabled && audioRef.current) {
                audioRef.current.play().catch(() => {});
              }
              // Show notification
              if (notificationsEnabled && 'Notification' in window && Notification.permission === 'granted') {
                new Notification(`New message from ${chat.user.name}`, {
                  body: newMessage.content.slice(0, 100),
                  icon: '/favicon.ico',
                });
              }
            }
          }
        });
      }

      previousChatsRef.current = chats;
      setActiveChats(chats);
      setError(null);
    } catch (err) {
      console.error('Failed to fetch chats:', err);
      setError('Failed to load chats');
    } finally {
      setLoading(false);
    }
  }, [filter, setActiveChats, soundEnabled, notificationsEnabled]);

  // Initial fetch and polling
  useEffect(() => {
    fetchChats();
    const interval = setInterval(fetchChats, 5000); // Refresh every 5 seconds
    return () => clearInterval(interval);
  }, [fetchChats]);

  // Get selected chat
  const selectedChat = activeChats.find((c) => c.id === selectedChatId);

  // Handle chat selection
  const handleSelectChat = async (chatId: string) => {
    setSelectedChatId(chatId);
    markMessagesAsRead(chatId);

    // Claim chat if not already assigned
    const chat = activeChats.find((c) => c.id === chatId);
    if (chat && !chat.assigned_agent_id && session) {
      try {
        await claimLiveChat(chatId);
        fetchChats();
      } catch (err) {
        console.error('Failed to claim chat:', err);
      }
    }
  };

  // Handle send reply
  const handleSendReply = async (message: string) => {
    if (!selectedChatId || !session) return;

    setSending(true);
    try {
      const newMessage = await sendAdminReply(selectedChatId, message);
      addMessage(selectedChatId, newMessage);
    } catch (err) {
      console.error('Failed to send reply:', err);
    } finally {
      setSending(false);
    }
  };

  // Handle resolve chat
  const handleResolve = async () => {
    if (!selectedChatId) return;

    setResolving(true);
    try {
      await resolveLiveChat(selectedChatId);
      setSelectedChatId(null);
      fetchChats();
    } catch (err) {
      console.error('Failed to resolve chat:', err);
    } finally {
      setResolving(false);
    }
  };

  // Filter chats
  const filteredChats = activeChats.filter((chat) => {
    if (filter === 'all') return chat.status !== 'resolved';
    return chat.status === filter;
  });

  return (
    <AdminLayout>
      <div className="flex h-[calc(100vh-120px)] gap-6">
        {/* Chat Queue Panel */}
        <div className="w-96 flex-shrink-0 glass-card rounded-2xl flex flex-col">
          {/* Header */}
          <div className="p-4 border-b border-white/10">
            <div className="flex items-center justify-between mb-4">
              <h2 className="text-lg font-semibold text-text">Chat Queue</h2>
              <button
                onClick={fetchChats}
                className="p-2 rounded-lg hover:bg-white/10 transition-colors text-text-secondary"
                title="Refresh"
              >
                <svg className="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15" />
                </svg>
              </button>
            </div>

            {/* Filter Tabs */}
            <div className="flex gap-2">
              {(['all', 'waiting', 'active'] as const).map((f) => (
                <button
                  key={f}
                  onClick={() => setFilter(f)}
                  className={`px-3 py-1.5 rounded-lg text-sm font-medium transition-colors ${
                    filter === f
                      ? 'bg-primary/20 text-primary border border-primary/30'
                      : 'bg-white/5 text-text-secondary hover:bg-white/10'
                  }`}
                >
                  {f.charAt(0).toUpperCase() + f.slice(1)}
                  {f === 'waiting' && (
                    <span className="ml-1.5 px-1.5 py-0.5 rounded bg-yellow-500/20 text-yellow-400 text-xs">
                      {activeChats.filter((c) => c.status === 'waiting').length}
                    </span>
                  )}
                </button>
              ))}
            </div>
          </div>

          {/* Notification Settings */}
          <div className="px-4 py-3 border-b border-white/10 flex items-center gap-4">
            <label className="flex items-center gap-2 text-sm text-text-secondary cursor-pointer">
              <input
                type="checkbox"
                checked={notificationsEnabled}
                onChange={(e) => setNotificationsEnabled(e.target.checked)}
                className="rounded border-white/20 bg-white/5 text-primary focus:ring-primary/30"
              />
              Notifications
            </label>
          </div>

          {/* Chat List */}
          <div className="flex-1 overflow-y-auto p-4 space-y-3">
            {loading ? (
              // Loading skeleton
              Array.from({ length: 5 }).map((_, i) => (
                <div key={i} className="animate-pulse p-4 rounded-xl bg-white/5">
                  <div className="flex items-start gap-3">
                    <div className="w-10 h-10 rounded-full bg-white/10" />
                    <div className="flex-1">
                      <div className="h-4 bg-white/10 rounded w-2/3 mb-2" />
                      <div className="h-3 bg-white/10 rounded w-full mb-2" />
                      <div className="flex gap-2">
                        <div className="h-5 bg-white/10 rounded w-16" />
                        <div className="h-5 bg-white/10 rounded w-16" />
                      </div>
                    </div>
                  </div>
                </div>
              ))
            ) : error ? (
              <div className="text-center py-8">
                <p className="text-coral">{error}</p>
                <button
                  onClick={fetchChats}
                  className="mt-2 text-sm text-primary hover:underline"
                >
                  Try again
                </button>
              </div>
            ) : filteredChats.length === 0 ? (
              <div className="text-center py-8">
                <svg
                  className="w-12 h-12 text-text-muted mx-auto mb-3"
                  fill="none"
                  viewBox="0 0 24 24"
                  stroke="currentColor"
                >
                  <path
                    strokeLinecap="round"
                    strokeLinejoin="round"
                    strokeWidth={1}
                    d="M20 13V6a2 2 0 00-2-2H6a2 2 0 00-2 2v7m16 0v5a2 2 0 01-2 2H6a2 2 0 01-2-2v-5m16 0h-2.586a1 1 0 00-.707.293l-2.414 2.414a1 1 0 01-.707.293h-3.172a1 1 0 01-.707-.293l-2.414-2.414A1 1 0 006.586 13H4"
                  />
                </svg>
                <p className="text-text-muted">No chats in queue</p>
              </div>
            ) : (
              filteredChats.map((chat) => (
                <ChatQueueItem
                  key={chat.id}
                  chat={chat}
                  isSelected={chat.id === selectedChatId}
                  onClick={() => handleSelectChat(chat.id)}
                />
              ))
            )}
          </div>
        </div>

        {/* Chat Panel */}
        <div className="flex-1 glass-card rounded-2xl flex flex-col">
          {selectedChat ? (
            <>
              {/* Chat Header */}
              <div className="p-4 border-b border-white/10">
                <div className="flex items-center justify-between">
                  <div className="flex items-center gap-3">
                    <div className="w-10 h-10 rounded-full bg-gradient-to-br from-primary/50 to-secondary/50 flex items-center justify-center text-white font-medium">
                      {selectedChat.user.name.charAt(0).toUpperCase()}
                    </div>
                    <div>
                      <h3 className="font-medium text-text">{selectedChat.user.name}</h3>
                      <p className="text-xs text-text-secondary">
                        {selectedChat.user.email || 'No email'}
                      </p>
                    </div>
                  </div>

                  <div className="flex items-center gap-2">
                    <button
                      onClick={handleResolve}
                      disabled={resolving}
                      className="px-4 py-2 rounded-lg bg-green-500/20 text-green-400 hover:bg-green-500/30 transition-colors text-sm font-medium disabled:opacity-50"
                    >
                      {resolving ? 'Resolving...' : 'Mark Resolved'}
                    </button>
                    <button
                      onClick={() => setSelectedChatId(null)}
                      className="p-2 rounded-lg hover:bg-white/10 transition-colors text-text-secondary"
                    >
                      <svg className="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
                      </svg>
                    </button>
                  </div>
                </div>

                {/* User Context */}
                {(selectedChat.user.fitness_level || selectedChat.user.goals?.length) && (
                  <div className="mt-3 p-3 rounded-lg bg-white/5 flex flex-wrap gap-3 text-xs">
                    {selectedChat.user.fitness_level && (
                      <span className="text-text-secondary">
                        Level: <span className="text-text capitalize">{selectedChat.user.fitness_level}</span>
                      </span>
                    )}
                    {selectedChat.user.goals && selectedChat.user.goals.length > 0 && (
                      <span className="text-text-secondary">
                        Goals: <span className="text-text">{selectedChat.user.goals.join(', ')}</span>
                      </span>
                    )}
                    {selectedChat.user.subscription_tier && (
                      <span className="text-text-secondary">
                        Plan: <span className="text-primary capitalize">{selectedChat.user.subscription_tier}</span>
                      </span>
                    )}
                  </div>
                )}

                {/* AI Handoff Context */}
                {selectedChat.ai_handoff_context && (
                  <div className="mt-3 p-3 rounded-lg bg-purple-500/10 border border-purple-500/20">
                    <div className="flex items-start gap-2">
                      <svg className="w-5 h-5 text-purple-400 flex-shrink-0 mt-0.5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9.663 17h4.673M12 3v1m6.364 1.636l-.707.707M21 12h-1M4 12H3m3.343-5.657l-.707-.707m2.828 9.9a5 5 0 117.072 0l-.548.547A3.374 3.374 0 0014 18.469V19a2 2 0 11-4 0v-.531c0-.895-.356-1.754-.988-2.386l-.548-.547z" />
                      </svg>
                      <div className="flex-1 min-w-0">
                        <p className="text-sm font-medium text-purple-400">AI Handoff</p>
                        <p className="text-sm text-text-secondary mt-1">
                          <strong>Reason:</strong> {selectedChat.ai_handoff_context.reason}
                        </p>
                        <p className="text-sm text-text-secondary mt-1">
                          <strong>Summary:</strong> {selectedChat.ai_handoff_context.conversation_summary}
                        </p>
                        <p className="text-sm text-text-secondary mt-1">
                          <strong>Sentiment:</strong> {selectedChat.ai_handoff_context.user_sentiment}
                        </p>
                      </div>
                    </div>
                  </div>
                )}
              </div>

              {/* Messages */}
              <ChatMessageList
                messages={selectedChat.messages}
                currentAdminId={session?.user.id}
              />

              {/* Reply Input */}
              <AdminReplyInput
                onSend={handleSendReply}
                disabled={sending}
                suggestedResponse={selectedChat.ai_handoff_context?.suggested_response}
              />
            </>
          ) : (
            // No chat selected
            <div className="flex-1 flex flex-col items-center justify-center text-center p-8">
              <svg
                className="w-16 h-16 text-text-muted mb-4"
                fill="none"
                viewBox="0 0 24 24"
                stroke="currentColor"
              >
                <path
                  strokeLinecap="round"
                  strokeLinejoin="round"
                  strokeWidth={1}
                  d="M8 12h.01M12 12h.01M16 12h.01M21 12c0 4.418-4.03 8-9 8a9.863 9.863 0 01-4.255-.949L3 20l1.395-3.72C3.512 15.042 3 13.574 3 12c0-4.418 4.03-8 9-8s9 3.582 9 8z"
                />
              </svg>
              <h3 className="text-lg font-medium text-text mb-2">Select a Chat</h3>
              <p className="text-text-secondary max-w-sm">
                Choose a conversation from the queue to view messages and respond to users.
              </p>
            </div>
          )}
        </div>
      </div>
    </AdminLayout>
  );
}
