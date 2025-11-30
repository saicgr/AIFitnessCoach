import { useState, useRef, useEffect } from 'react';
import { useNavigate, useLocation } from 'react-router-dom';
import { useMutation, useQuery } from '@tanstack/react-query';
import { useAppStore } from '../store';
import { sendChatMessage, getChatHistory } from '../api/client';
import type { ChatMessage, UserProfile, WorkoutContext, WorkoutScheduleContext, Workout } from '../types';
import { createLogger } from '../utils/logger';
import ChatActions from '../components/chat/ChatActions';
import { isSameDay, isThisWeek, getYesterday, getTomorrow, getTodayStart } from '../utils/dateUtils';
import { GlassCard, GlassButton } from '../components/ui';

const log = createLogger('chat');

interface MessageBubbleProps {
  message: ChatMessage;
  workoutId?: string;
}

function MessageBubble({ message, workoutId }: MessageBubbleProps) {
  const isUser = message.role === 'user';

  return (
    <div className={`flex ${isUser ? 'justify-end' : 'justify-start'} fade-in-up`}>
      {!isUser && (
        <div className="w-8 h-8 rounded-xl bg-gradient-to-br from-primary to-secondary flex items-center justify-center mr-3 flex-shrink-0 shadow-[0_0_15px_rgba(6,182,212,0.3)]">
          <svg className="w-4 h-4 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 3v4M3 5h4M6 17v4m-2-2h4m5-16l2.286 6.857L21 12l-5.714 2.143L13 21l-2.286-6.857L5 12l5.714-2.143L13 3z" />
          </svg>
        </div>
      )}
      <div
        className={`
          max-w-[80%] p-4 rounded-2xl
          ${isUser
            ? 'bg-gradient-to-br from-primary to-primary-dark text-white rounded-br-md shadow-[0_0_20px_rgba(6,182,212,0.3)]'
            : 'bg-white/10 backdrop-blur-sm border border-white/10 text-text rounded-bl-md'
          }
        `}
      >
        <p className="whitespace-pre-wrap text-sm leading-relaxed">{message.content}</p>
        {!isUser && message.intent && (
          <div className="mt-3">
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

function TypingIndicator() {
  return (
    <div className="flex justify-start fade-in-up">
      <div className="w-8 h-8 rounded-xl bg-gradient-to-br from-primary to-secondary flex items-center justify-center mr-3 flex-shrink-0">
        <svg className="w-4 h-4 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 3v4M3 5h4M6 17v4m-2-2h4m5-16l2.286 6.857L21 12l-5.714 2.143L13 21l-2.286-6.857L5 12l5.714-2.143L13 3z" />
        </svg>
      </div>
      <div className="bg-white/10 backdrop-blur-sm border border-white/10 text-text-secondary px-4 py-3 rounded-2xl rounded-bl-md">
        <div className="flex items-center gap-1">
          <div className="w-2 h-2 bg-primary rounded-full animate-bounce" style={{ animationDelay: '0ms' }} />
          <div className="w-2 h-2 bg-primary rounded-full animate-bounce" style={{ animationDelay: '150ms' }} />
          <div className="w-2 h-2 bg-primary rounded-full animate-bounce" style={{ animationDelay: '300ms' }} />
        </div>
      </div>
    </div>
  );
}

export default function Chat() {
  const navigate = useNavigate();
  const location = useLocation();
  const { user, workouts, chatHistory, setChatHistory, addChatMessage, clearChatHistory, onboardingData } = useAppStore();
  const [historyLoaded, setHistoryLoaded] = useState(false);

  // Get prefilled message from navigation state (e.g., from Metrics page "Report Injury" button)
  const prefillMessage = (location.state as { prefillMessage?: string })?.prefillMessage;

  const today = new Date().toISOString().split('T')[0];

  const todaysWorkout = workouts.find(w => {
    const scheduledDate = w.scheduled_date?.split('T')[0];
    return scheduledDate === today && !w.completed_at;
  }) || null;

  log.info('Chat context', {
    today,
    hasTodaysWorkout: !!todaysWorkout,
    workoutName: todaysWorkout?.name,
    exerciseCount: todaysWorkout?.exercises.length,
  });

  const [input, setInput] = useState(prefillMessage || '');
  const messagesEndRef = useRef<HTMLDivElement>(null);

  const scrollToBottom = () => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
  };

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
      log.info('Loaded chat history from database', { count: messages.length });
      return messages;
    },
    enabled: !!user?.id,
    staleTime: Infinity,
    refetchOnWindowFocus: false,
  });

  useEffect(() => {
    scrollToBottom();
  }, [chatHistory]);

  useEffect(() => {
    if (!historyLoaded && user?.id) return;

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
        greetingMessage = `${timeGreeting}, ${userName}! I see you have "${todaysWorkout.name}" scheduled for today with ${todaysWorkout.exercises.length} exercises. Ready to crush it? Let me know if you need any modifications or have questions!`;
      } else {
        greetingMessage = `${timeGreeting}, ${userName}! You don't have a workout scheduled for today. Would you like me to help you with anything? You can ask about your upcoming workouts, report an injury, or get fitness tips.`;
      }

      addChatMessage({
        role: 'assistant',
        content: greetingMessage,
      });
    }
  }, [today, todaysWorkout, chatHistory.length, onboardingData?.name, addChatMessage, historyLoaded, user?.id]);

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

      log.info('Sending chat with workout schedule', {
        hasYesterday: !!workoutSchedule.yesterday,
        hasToday: !!workoutSchedule.today,
        hasTomorrow: !!workoutSchedule.tomorrow,
        thisWeekCount: workoutSchedule.thisWeek.length,
        recentCompletedCount: workoutSchedule.recentCompleted.length,
      });

      return sendChatMessage({
        message,
        user_id: user?.id || 1,
        user_profile: userProfile,
        current_workout: workoutContext,
        workout_schedule: workoutSchedule,
        conversation_history: chatHistory,
      });
    },
    onSuccess: (response) => {
      addChatMessage({
        role: 'assistant',
        content: response.message,
        intent: response.intent,
        actionData: response.action_data,
      });
    },
    onError: (error) => {
      addChatMessage({
        role: 'assistant',
        content: 'Sorry, I encountered an error. Please try again.',
      });
      log.error('Chat request failed', error);
    },
  });

  const handleSend = () => {
    if (!input.trim() || chatMutation.isPending) return;

    const message = input.trim();
    setInput('');
    addChatMessage({ role: 'user', content: message });
    chatMutation.mutate(message);
  };

  const handleKeyDown = (e: React.KeyboardEvent) => {
    if (e.key === 'Enter' && !e.shiftKey) {
      e.preventDefault();
      handleSend();
    }
  };

  const suggestedMessages = [
    'Make my workout easier',
    'Add a core exercise',
    'Replace this with a home exercise',
    'I have a shoulder injury',
  ];

  return (
    <div className="min-h-screen bg-background flex flex-col">
      {/* Background decorations */}
      <div className="fixed inset-0 overflow-hidden pointer-events-none">
        <div className="absolute top-0 left-0 w-[400px] h-[400px] bg-primary/5 rounded-full blur-3xl" />
        <div className="absolute bottom-0 right-0 w-[300px] h-[300px] bg-secondary/5 rounded-full blur-3xl" />
      </div>

      {/* Header */}
      <header className="relative z-10 glass-heavy safe-area-top">
        <div className="max-w-2xl mx-auto px-4 py-4">
          <div className="flex items-center justify-between">
            <button
              onClick={() => navigate(-1)}
              className="p-2 hover:bg-white/10 rounded-xl transition-colors text-text-secondary hover:text-text"
            >
              <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 19l-7-7 7-7" />
              </svg>
            </button>
            <div className="flex items-center gap-3">
              <div className="w-10 h-10 rounded-xl bg-gradient-to-br from-primary to-secondary flex items-center justify-center shadow-[0_0_15px_rgba(6,182,212,0.3)]">
                <svg className="w-5 h-5 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 3v4M3 5h4M6 17v4m-2-2h4m5-16l2.286 6.857L21 12l-5.714 2.143L13 21l-2.286-6.857L5 12l5.714-2.143L13 3z" />
                </svg>
              </div>
              <div>
                <h1 className="font-semibold text-text">AI Coach</h1>
                <p className="text-xs text-text-secondary">Always here to help</p>
              </div>
            </div>
            <button
              onClick={clearChatHistory}
              className="p-2 hover:bg-white/10 rounded-xl transition-colors text-text-secondary hover:text-text"
              title="Clear chat"
            >
              <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" />
              </svg>
            </button>
          </div>
        </div>
      </header>

      {/* Messages */}
      <main className="flex-1 overflow-y-auto relative z-10">
        <div className="max-w-2xl mx-auto p-4 space-y-4">
          {isLoadingHistory ? (
            <div className="flex justify-center py-12">
              <div className="flex items-center gap-3 text-text-secondary">
                <svg className="w-5 h-5 animate-spin" fill="none" viewBox="0 0 24 24">
                  <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4" />
                  <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z" />
                </svg>
                <span>Loading conversation...</span>
              </div>
            </div>
          ) : chatHistory.length === 0 ? (
            <div className="text-center py-12 fade-in-up">
              <div className="w-20 h-20 bg-gradient-to-br from-primary to-secondary rounded-2xl flex items-center justify-center mx-auto mb-6 shadow-[0_0_30px_rgba(6,182,212,0.4)]">
                <svg className="w-10 h-10 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M5 3v4M3 5h4M6 17v4m-2-2h4m5-16l2.286 6.857L21 12l-5.714 2.143L13 21l-2.286-6.857L5 12l5.714-2.143L13 3z" />
                </svg>
              </div>
              <h2 className="text-2xl font-bold text-text mb-2">
                Hey there!
              </h2>
              <p className="text-text-secondary mb-8 max-w-sm mx-auto">
                I'm your AI fitness coach. Ask me to modify your workout,
                get exercise tips, or report any injuries.
              </p>

              {todaysWorkout && (
                <GlassCard className="p-4 mb-6 text-left inline-block max-w-sm" variant="default">
                  <div className="flex items-center gap-3">
                    <div className="w-10 h-10 rounded-xl bg-accent/20 flex items-center justify-center">
                      <svg className="w-5 h-5 text-accent" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2" />
                      </svg>
                    </div>
                    <div>
                      <p className="text-xs text-text-secondary mb-0.5">Today's Workout</p>
                      <p className="font-semibold text-text">{todaysWorkout.name}</p>
                      <p className="text-sm text-text-secondary">
                        {todaysWorkout.exercises.length} exercises
                      </p>
                    </div>
                  </div>
                </GlassCard>
              )}

              <div className="flex flex-wrap gap-2 justify-center">
                {suggestedMessages.map((msg) => (
                  <button
                    key={msg}
                    onClick={() => {
                      addChatMessage({ role: 'user', content: msg });
                      chatMutation.mutate(msg);
                    }}
                    className="px-4 py-2 bg-white/5 border border-white/10 rounded-xl text-sm text-text-secondary hover:bg-white/10 hover:text-text transition-all"
                  >
                    {msg}
                  </button>
                ))}
              </div>
            </div>
          ) : (
            <>
              {chatHistory.map((msg, index) => (
                <MessageBubble key={index} message={msg} workoutId={todaysWorkout?.id} />
              ))}
              {chatMutation.isPending && <TypingIndicator />}
              <div ref={messagesEndRef} />
            </>
          )}
        </div>
      </main>

      {/* Input */}
      <div className="relative z-10 glass-heavy safe-area-bottom">
        <div className="max-w-2xl mx-auto p-4">
          <div className="flex gap-3">
            <input
              type="text"
              value={input}
              onChange={(e) => setInput(e.target.value)}
              onKeyDown={handleKeyDown}
              placeholder="Ask your AI coach..."
              className="
                flex-1 px-4 py-3
                bg-white/5 border border-white/10
                rounded-xl text-text placeholder:text-text-muted
                focus:outline-none focus:border-primary focus:ring-2 focus:ring-primary/30
                transition-all
              "
            />
            <GlassButton
              onClick={handleSend}
              disabled={!input.trim() || chatMutation.isPending}
              icon={
                <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 19l9 2-9-18-9 18 9-2zm0 0v-8" />
                </svg>
              }
            >
              Send
            </GlassButton>
          </div>
        </div>
      </div>
    </div>
  );
}
