import { useState, useRef, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { useMutation } from '@tanstack/react-query';
import { useAppStore } from '../store';
import { sendChatMessage } from '../api/client';
import type { ChatMessage, UserProfile, WorkoutContext, WorkoutScheduleContext, Workout } from '../types';
import { createLogger } from '../utils/logger';
import ChatActions from '../components/chat/ChatActions';
import { isSameDay, isThisWeek, getYesterday, getTomorrow, getTodayStart } from '../utils/dateUtils';

const log = createLogger('chat');

interface MessageBubbleProps {
  message: ChatMessage;
  workoutId?: number;
}

function MessageBubble({ message, workoutId }: MessageBubbleProps) {
  const isUser = message.role === 'user';

  return (
    <div className={`flex ${isUser ? 'justify-end' : 'justify-start'}`}>
      <div
        className={`max-w-[80%] p-4 rounded-2xl ${
          isUser
            ? 'bg-primary text-white rounded-br-md'
            : 'bg-gray-100 text-gray-900 rounded-bl-md'
        }`}
      >
        <p className="whitespace-pre-wrap">{message.content}</p>
        {!isUser && message.intent && (
          <ChatActions
            intent={message.intent}
            actionData={message.actionData}
            workoutId={workoutId}
          />
        )}
      </div>
    </div>
  );
}

export default function Chat() {
  const navigate = useNavigate();
  const { user, currentWorkout, workouts, chatHistory, addChatMessage, clearChatHistory } = useAppStore();

  // Use currentWorkout if available, otherwise use first uncompleted workout from workouts list
  const activeWorkout = currentWorkout || workouts.find(w => !w.completed_at) || null;

  log.info('Chat context', {
    hasCurrentWorkout: !!currentWorkout,
    hasActiveWorkout: !!activeWorkout,
    workoutName: activeWorkout?.name,
    exerciseCount: activeWorkout?.exercises.length,
  });
  const [input, setInput] = useState('');
  const messagesEndRef = useRef<HTMLDivElement>(null);

  const scrollToBottom = () => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
  };

  useEffect(() => {
    scrollToBottom();
  }, [chatHistory]);

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

      const workoutContext: WorkoutContext | undefined = activeWorkout
        ? {
            id: activeWorkout.id,
            name: activeWorkout.name,
            type: activeWorkout.type,
            difficulty: activeWorkout.difficulty,
            exercises: activeWorkout.exercises,
          }
        : undefined;

      // Build workout schedule context for AI
      const yesterday = getYesterday();
      const today = getTodayStart();
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
        today: findWorkoutForDate(today),
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
      {/* Header */}
      <header className="bg-primary text-white p-4">
        <div className="max-w-2xl mx-auto flex items-center justify-between">
          <button
            onClick={() => navigate(-1)}
            className="text-white/70 hover:text-white"
          >
            ← Back
          </button>
          <span className="font-semibold">AI Coach</span>
          <button
            onClick={clearChatHistory}
            className="text-white/70 hover:text-white text-sm"
          >
            Clear
          </button>
        </div>
      </header>

      {/* Messages */}
      <main className="flex-1 overflow-y-auto p-4">
        <div className="max-w-2xl mx-auto space-y-4">
          {chatHistory.length === 0 ? (
            <div className="text-center py-12">
              <div className="w-20 h-20 bg-primary/10 text-primary rounded-full flex items-center justify-center text-3xl mx-auto mb-4">
                AI
              </div>
              <h2 className="text-xl font-bold text-gray-900 mb-2">
                Hey there!
              </h2>
              <p className="text-gray-600 mb-6">
                I'm your AI fitness coach. Ask me to modify your workout,
                get exercise tips, or report any injuries.
              </p>
              {activeWorkout && (
                <div className="bg-white p-4 rounded-xl border border-gray-200 mb-6 text-left">
                  <p className="text-sm text-gray-500 mb-1">Current Workout</p>
                  <p className="font-semibold text-gray-900">{activeWorkout.name}</p>
                  <p className="text-sm text-gray-600">
                    {activeWorkout.exercises.length} exercises
                  </p>
                </div>
              )}
              <div className="flex flex-wrap gap-2 justify-center">
                {suggestedMessages.map((msg) => (
                  <button
                    key={msg}
                    onClick={() => {
                      addChatMessage({ role: 'user', content: msg });
                      chatMutation.mutate(msg);
                    }}
                    className="px-4 py-2 bg-white border border-gray-200 rounded-full text-sm text-gray-700 hover:bg-gray-50"
                  >
                    {msg}
                  </button>
                ))}
              </div>
            </div>
          ) : (
            <>
              {chatHistory.map((msg, index) => (
                <MessageBubble key={index} message={msg} workoutId={activeWorkout?.id} />
              ))}
              {chatMutation.isPending && (
                <div className="flex justify-start">
                  <div className="bg-gray-100 text-gray-500 p-4 rounded-2xl rounded-bl-md">
                    Thinking...
                  </div>
                </div>
              )}
              <div ref={messagesEndRef} />
            </>
          )}
        </div>
      </main>

      {/* Input */}
      <div className="bg-white border-t border-gray-200 p-4">
        <div className="max-w-2xl mx-auto flex gap-3">
          <input
            type="text"
            value={input}
            onChange={(e) => setInput(e.target.value)}
            onKeyDown={handleKeyDown}
            placeholder="Ask your AI coach..."
            className="flex-1 px-4 py-3 border border-gray-300 rounded-xl focus:ring-2 focus:ring-primary focus:border-transparent"
          />
          <button
            onClick={handleSend}
            disabled={!input.trim() || chatMutation.isPending}
            className="px-6 py-3 bg-primary text-white rounded-xl font-semibold hover:bg-primary-dark disabled:opacity-50 disabled:cursor-not-allowed"
          >
            Send
          </button>
        </div>
      </div>
    </div>
  );
}
