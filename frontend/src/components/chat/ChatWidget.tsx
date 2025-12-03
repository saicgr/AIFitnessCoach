import { useState, useRef, useEffect, useCallback } from 'react';
import { createPortal } from 'react-dom';
import { motion, AnimatePresence } from 'framer-motion';
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { useAppStore } from '../../store';
import { sendChatMessage, getChatHistory } from '../../api/client';
import type { ChatMessage, UserProfile, WorkoutContext, WorkoutScheduleContext, Workout } from '../../types';
import { createLogger } from '../../utils/logger';
import ChatActions from './ChatActions';
import ChatWidgetToggle from './ChatWidgetToggle';
import ChatWidgetHeader from './ChatWidgetHeader';
import { isSameDay, isThisWeek, getYesterday, getTomorrow, getTodayStart } from '../../utils/dateUtils';

const log = createLogger('chat-widget');

const MAX_FILE_SIZE = 10 * 1024 * 1024;

interface MessageBubbleProps {
  message: ChatMessage;
  workoutId?: string;
  compact?: boolean;
}

function MessageBubble({ message, workoutId, compact }: MessageBubbleProps) {
  const isUser = message.role === 'user';

  return (
    <div className={`flex ${isUser ? 'justify-end' : 'justify-start'} fade-in-up`}>
      {!isUser && (
        <div className={`${compact ? 'w-6 h-6' : 'w-8 h-8'} rounded-xl bg-gradient-to-br from-primary to-secondary flex items-center justify-center mr-2 flex-shrink-0 shadow-[0_0_15px_rgba(6,182,212,0.3)]`}>
          <svg className={`${compact ? 'w-3 h-3' : 'w-4 h-4'} text-white`} fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 3v4M3 5h4M6 17v4m-2-2h4m5-16l2.286 6.857L21 12l-5.714 2.143L13 21l-2.286-6.857L5 12l5.714-2.143L13 3z" />
          </svg>
        </div>
      )}
      <div
        className={`
          max-w-[85%] ${compact ? 'p-2.5 text-xs' : 'p-3 text-sm'} rounded-2xl
          ${isUser
            ? 'bg-gradient-to-br from-primary to-primary-dark text-white rounded-br-md shadow-[0_0_20px_rgba(6,182,212,0.3)]'
            : 'bg-white/10 backdrop-blur-sm border border-white/10 text-text rounded-bl-md'
          }
        `}
      >
        {message.imagePreview && (
          <div className="mb-2">
            <img
              src={`data:image/jpeg;base64,${message.imagePreview}`}
              alt="Food"
              className={`rounded-lg max-w-full ${compact ? 'max-h-24' : 'max-h-32'} object-cover`}
            />
          </div>
        )}
        <p className="whitespace-pre-wrap leading-relaxed">{message.content}</p>
        {!isUser && message.intent && (
          <div className="mt-2">
            <ChatActions
              intent={message.intent}
              actionData={message.actionData}
              workoutId={workoutId}
            />
          </div>
        )}
      </div>
    </div>
  );
}

function TypingIndicator({ compact }: { compact?: boolean }) {
  return (
    <div className="flex justify-start fade-in-up">
      <div className={`${compact ? 'w-6 h-6' : 'w-8 h-8'} rounded-xl bg-gradient-to-br from-primary to-secondary flex items-center justify-center mr-2 flex-shrink-0`}>
        <svg className={`${compact ? 'w-3 h-3' : 'w-4 h-4'} text-white`} fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 3v4M3 5h4M6 17v4m-2-2h4m5-16l2.286 6.857L21 12l-5.714 2.143L13 21l-2.286-6.857L5 12l5.714-2.143L13 3z" />
        </svg>
      </div>
      <div className="bg-white/10 backdrop-blur-sm border border-white/10 text-text-secondary px-3 py-2 rounded-2xl rounded-bl-md">
        <div className="flex items-center gap-1">
          <div className="w-1.5 h-1.5 bg-primary rounded-full animate-bounce" style={{ animationDelay: '0ms' }} />
          <div className="w-1.5 h-1.5 bg-primary rounded-full animate-bounce" style={{ animationDelay: '150ms' }} />
          <div className="w-1.5 h-1.5 bg-primary rounded-full animate-bounce" style={{ animationDelay: '300ms' }} />
        </div>
      </div>
    </div>
  );
}

export default function ChatWidget() {
  const queryClient = useQueryClient();
  const {
    user,
    workouts,
    chatHistory,
    setChatHistory,
    addChatMessage,
    onboardingData,
    chatWidgetState,
    setChatWidgetOpen,
  } = useAppStore();

  const { isOpen, sizeMode } = chatWidgetState;
  const isCompact = sizeMode === 'medium';

  const [input, setInput] = useState('');
  const [selectedImage, setSelectedImage] = useState<string | null>(null);
  const [historyLoaded, setHistoryLoaded] = useState(false);
  const messagesEndRef = useRef<HTMLDivElement>(null);
  const fileInputRef = useRef<HTMLInputElement>(null);

  const today = new Date().toISOString().split('T')[0];

  const todaysWorkout = workouts.find(w => {
    const scheduledDate = w.scheduled_date?.split('T')[0];
    return scheduledDate === today && !w.completed_at;
  }) || null;

  // Handle image selection
  const handleImageSelect = useCallback((event: React.ChangeEvent<HTMLInputElement>) => {
    const file = event.target.files?.[0];
    if (!file) return;

    if (!file.type.startsWith('image/')) {
      log.error('Invalid file type:', file.type);
      return;
    }

    if (file.size > MAX_FILE_SIZE) {
      log.error('File too large:', file.size);
      return;
    }

    const reader = new FileReader();
    reader.onloadend = () => {
      const base64 = reader.result as string;
      const base64Data = base64.split(',')[1];
      setSelectedImage(base64Data);
    };
    reader.readAsDataURL(file);

    if (fileInputRef.current) {
      fileInputRef.current.value = '';
    }
  }, []);

  const removeSelectedImage = useCallback(() => {
    setSelectedImage(null);
  }, []);

  const scrollToBottom = () => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
  };

  // Load chat history
  const { isLoading: isLoadingHistory } = useQuery({
    queryKey: ['chatHistory', user?.id],
    queryFn: async () => {
      if (!user?.id) return [];
      const history = await getChatHistory(user.id);
      const messages: ChatMessage[] = history.map(item => ({
        role: item.role,
        content: item.content,
        actionData: item.action_data,
      }));
      setChatHistory(messages);
      setHistoryLoaded(true);
      return messages;
    },
    enabled: !!user?.id && isOpen,
    staleTime: Infinity,
    refetchOnWindowFocus: false,
  });

  useEffect(() => {
    if (isOpen) {
      scrollToBottom();
    }
  }, [chatHistory, isOpen]);

  // First visit greeting
  useEffect(() => {
    if (!historyLoaded || !user?.id || !isOpen) return;

    const lastVisitDate = localStorage.getItem('lastChatVisitDate');
    const isFirstVisitToday = lastVisitDate !== today;

    if (isFirstVisitToday && chatHistory.length === 0) {
      localStorage.setItem('lastChatVisitDate', today);

      const hour = new Date().getHours();
      let timeGreeting = 'Hello';
      if (hour < 12) timeGreeting = 'Good morning';
      else if (hour < 17) timeGreeting = 'Good afternoon';
      else timeGreeting = 'Good evening';

      const userName = onboardingData?.name || 'there';

      let greetingMessage = '';
      if (todaysWorkout) {
        greetingMessage = `${timeGreeting}, ${userName}! I see you have "${todaysWorkout.name}" scheduled for today. Ready to crush it?`;
      } else {
        greetingMessage = `${timeGreeting}, ${userName}! You don't have a workout scheduled for today. How can I help you?`;
      }

      addChatMessage({
        role: 'assistant',
        content: greetingMessage,
      });
    }
  }, [today, todaysWorkout, chatHistory.length, onboardingData?.name, addChatMessage, historyLoaded, user?.id, isOpen]);

  // Chat mutation
  const chatMutation = useMutation({
    mutationFn: async (message: string) => {
      const userProfile: UserProfile | undefined = user
        ? {
            id: user.id,
            fitness_level: user.fitness_level,
            goals: user.goals,
            equipment: user.equipment,
            active_injuries: user.active_injuries,
          }
        : undefined;

      const workoutContext: WorkoutContext | undefined = todaysWorkout
        ? {
            id: todaysWorkout.id,
            name: todaysWorkout.name,
            type: todaysWorkout.type,
            difficulty: todaysWorkout.difficulty,
            exercises: todaysWorkout.exercises,
          }
        : undefined;

      const yesterday = getYesterday();
      const todayDate = getTodayStart();
      const tomorrow = getTomorrow();

      const toWorkoutContext = (w: Workout): WorkoutContext => ({
        id: w.id,
        name: w.name,
        type: w.type,
        difficulty: w.difficulty,
        exercises: w.exercises,
        scheduled_date: w.scheduled_date,
        is_completed: !!w.completed_at,
      });

      const findWorkoutForDate = (date: Date): WorkoutContext | null => {
        const workout = workouts.find(w =>
          w.scheduled_date && isSameDay(new Date(w.scheduled_date), date)
        );
        return workout ? toWorkoutContext(workout) : null;
      };

      const workoutSchedule: WorkoutScheduleContext = {
        yesterday: findWorkoutForDate(yesterday),
        today: findWorkoutForDate(todayDate),
        tomorrow: findWorkoutForDate(tomorrow),
        thisWeek: workouts
          .filter(w => w.scheduled_date && isThisWeek(new Date(w.scheduled_date)))
          .map(toWorkoutContext),
        recentCompleted: workouts
          .filter(w => w.completed_at)
          .slice(0, 5)
          .map(toWorkoutContext),
      };

      return sendChatMessage({
        message,
        user_id: user?.id || 1,
        user_profile: userProfile,
        current_workout: workoutContext,
        workout_schedule: workoutSchedule,
        conversation_history: chatHistory,
        image_base64: selectedImage || undefined,
      });
    },
    onSuccess: (response) => {
      addChatMessage({
        role: 'assistant',
        content: response.message,
        intent: response.intent,
        actionData: response.action_data,
      });
      // Invalidate workouts cache if workout was modified
      if (response.intent && ['add_exercise', 'remove_exercise', 'swap_workout', 'modify_intensity', 'reschedule', 'delete_workout'].includes(response.intent)) {
        queryClient.invalidateQueries({ queryKey: ['workouts'] });
      }
    },
    onError: () => {
      addChatMessage({
        role: 'assistant',
        content: 'Sorry, I encountered an error. Please try again.',
      });
    },
  });

  const handleSend = () => {
    if ((!input.trim() && !selectedImage) || chatMutation.isPending) return;

    const message = input.trim() || (selectedImage ? 'What did I eat?' : '');
    const imageToSend = selectedImage;

    setInput('');
    setSelectedImage(null);

    addChatMessage({
      role: 'user',
      content: message,
      imagePreview: imageToSend || undefined,
    });

    chatMutation.mutate(message);
  };

  const handleKeyDown = (e: React.KeyboardEvent) => {
    if (e.key === 'Enter' && !e.shiftKey) {
      e.preventDefault();
      handleSend();
    }
    if (e.key === 'Escape') {
      setChatWidgetOpen(false);
    }
  };

  const suggestedMessages = [
    'Make workout easier',
    'Add core exercise',
    'What did I eat?',
  ];

  // Don't render during SSR or if user not authenticated
  if (typeof window === 'undefined' || !user) return null;

  const widgetContent = (
    <div className="fixed bottom-6 right-6 z-50 flex flex-col items-end gap-4">
      <AnimatePresence mode="wait">
        {isOpen ? (
          <motion.div
            key="panel"
            initial={{ opacity: 0, scale: 0.9, y: 20 }}
            animate={{ opacity: 1, scale: 1, y: 0 }}
            exit={{ opacity: 0, scale: 0.9, y: 20 }}
            transition={{ type: 'spring', stiffness: 300, damping: 30 }}
            className={`
              flex flex-col bg-background/95 backdrop-blur-xl border border-white/10 rounded-2xl shadow-2xl overflow-hidden
              ${sizeMode === 'maximized'
                ? 'fixed inset-0 w-full h-full rounded-none'
                : 'w-[400px] h-[600px] max-h-[80vh]'
              }
            `}
            style={sizeMode === 'maximized' ? { bottom: 0, right: 0 } : {}}
          >
            {/* Header */}
            <ChatWidgetHeader />

            {/* Messages */}
            <div className="flex-1 overflow-y-auto p-3 space-y-3">
              {isLoadingHistory ? (
                <div className="flex justify-center py-8">
                  <div className="flex items-center gap-2 text-text-secondary text-sm">
                    <svg className="w-4 h-4 animate-spin" fill="none" viewBox="0 0 24 24">
                      <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4" />
                      <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z" />
                    </svg>
                    <span>Loading...</span>
                  </div>
                </div>
              ) : chatHistory.length === 0 ? (
                <div className="text-center py-6 fade-in-up">
                  <div className="w-14 h-14 bg-gradient-to-br from-primary to-secondary rounded-xl flex items-center justify-center mx-auto mb-4 shadow-[0_0_20px_rgba(6,182,212,0.3)]">
                    <svg className="w-7 h-7 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M5 3v4M3 5h4M6 17v4m-2-2h4m5-16l2.286 6.857L21 12l-5.714 2.143L13 21l-2.286-6.857L5 12l5.714-2.143L13 3z" />
                    </svg>
                  </div>
                  <h3 className="font-semibold text-text mb-1">Hey there!</h3>
                  <p className="text-text-secondary text-xs mb-4">
                    I'm your AI coach. Ask me anything!
                  </p>
                  <div className="flex flex-wrap gap-1.5 justify-center">
                    {suggestedMessages.map((msg) => (
                      <button
                        key={msg}
                        onClick={() => {
                          addChatMessage({ role: 'user', content: msg });
                          chatMutation.mutate(msg);
                        }}
                        className="px-3 py-1.5 bg-white/5 border border-white/10 rounded-lg text-xs text-text-secondary hover:bg-white/10 hover:text-text transition-all"
                      >
                        {msg}
                      </button>
                    ))}
                  </div>
                </div>
              ) : (
                <>
                  {chatHistory.map((msg, index) => (
                    <MessageBubble key={index} message={msg} workoutId={todaysWorkout?.id} compact={isCompact} />
                  ))}
                  {chatMutation.isPending && <TypingIndicator compact={isCompact} />}
                  <div ref={messagesEndRef} />
                </>
              )}
            </div>

            {/* Input */}
            <div className="border-t border-white/10 p-3">
              {/* Image Preview */}
              {selectedImage && (
                <div className="mb-2 relative inline-block">
                  <img
                    src={`data:image/jpeg;base64,${selectedImage}`}
                    alt="Selected food"
                    className="rounded-lg max-h-20 object-cover"
                  />
                  <button
                    onClick={removeSelectedImage}
                    className="absolute -top-1.5 -right-1.5 w-5 h-5 bg-red-500 hover:bg-red-600 rounded-full flex items-center justify-center text-white transition-colors"
                  >
                    <svg className="w-3 h-3" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
                    </svg>
                  </button>
                </div>
              )}

              <div className="flex gap-2">
                <input
                  ref={fileInputRef}
                  type="file"
                  accept="image/*"
                  onChange={handleImageSelect}
                  className="hidden"
                />

                <button
                  onClick={() => fileInputRef.current?.click()}
                  disabled={chatMutation.isPending}
                  className={`
                    p-2.5 rounded-xl border transition-all flex-shrink-0
                    ${selectedImage
                      ? 'bg-primary/20 border-primary text-primary'
                      : 'bg-white/5 border-white/10 text-text-secondary hover:bg-white/10 hover:text-text'
                    }
                    disabled:opacity-50 disabled:cursor-not-allowed
                  `}
                  title="Upload food photo"
                >
                  <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M3 9a2 2 0 012-2h.93a2 2 0 001.664-.89l.812-1.22A2 2 0 0110.07 4h3.86a2 2 0 011.664.89l.812 1.22A2 2 0 0018.07 7H19a2 2 0 012 2v9a2 2 0 01-2 2H5a2 2 0 01-2-2V9z" />
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 13a3 3 0 11-6 0 3 3 0 016 0z" />
                  </svg>
                </button>

                <input
                  type="text"
                  value={input}
                  onChange={(e) => setInput(e.target.value)}
                  onKeyDown={handleKeyDown}
                  placeholder={selectedImage ? "Describe meal..." : "Ask your coach..."}
                  className="
                    flex-1 px-3 py-2.5 text-sm
                    bg-white/5 border border-white/10
                    rounded-xl text-text placeholder:text-text-muted
                    focus:outline-none focus:border-primary focus:ring-2 focus:ring-primary/30
                    transition-all
                  "
                />

                <button
                  onClick={handleSend}
                  disabled={(!input.trim() && !selectedImage) || chatMutation.isPending}
                  className={`
                    p-2.5 rounded-xl transition-all flex-shrink-0
                    bg-gradient-to-r from-primary to-primary-dark
                    text-white
                    shadow-[0_0_15px_rgba(6,182,212,0.3)]
                    hover:shadow-[0_0_20px_rgba(6,182,212,0.4)]
                    disabled:opacity-50 disabled:cursor-not-allowed
                    active:scale-95
                  `}
                >
                  <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 19l9 2-9-18-9 18 9-2zm0 0v-8" />
                  </svg>
                </button>
              </div>
            </div>
          </motion.div>
        ) : (
          <ChatWidgetToggle key="toggle" />
        )}
      </AnimatePresence>
    </div>
  );

  return createPortal(widgetContent, document.body);
}
