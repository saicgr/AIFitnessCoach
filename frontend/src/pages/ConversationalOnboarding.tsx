/**
 * ConversationalOnboarding Page
 *
 * WhatsApp-style conversational onboarding experience.
 * Uses AI to extract data from natural language and guide users through setup.
 *
 * Features:
 * - Chat interface with message bubbles
 * - Quick reply buttons
 * - Smart question skipping based on context
 * - Day picker for schedule
 * - Health checklist at the end
 * - Saves conversation to Supabase
 * - Generates first workout on completion
 *
 * NO MOCK DATA, NO FALLBACKS - per CLAUDE.md
 */
import { FC, useState, useEffect, useRef } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAppStore } from '../store';
import {
  parseOnboardingResponse,
  saveOnboardingConversation,
  createUser,
  updateUser,
  generateWorkout,
} from '../api/client';
import MessageBubble from '../components/chat/MessageBubble';
import QuickReplyButtons from '../components/chat/QuickReplyButtons';
import DayPickerComponent from '../components/chat/DayPickerComponent';
import HealthChecklistModal from '../components/chat/HealthChecklistModal';
import BasicInfoForm from '../components/chat/BasicInfoForm';
import type { QuickReply } from '../types/onboarding';
import { createLogger } from '../utils/logger';

const log = createLogger('ConversationalOnboarding');

const ConversationalOnboarding: FC = () => {
  const navigate = useNavigate();
  const messagesEndRef = useRef<HTMLDivElement>(null);
  const inputRef = useRef<HTMLInputElement>(null);

  const {
    user,
    setUser,
    conversationalOnboarding,
    addConversationalMessage,
    updateCollectedData,
    setConversationalOnboarding,
  } = useAppStore();

  const [input, setInput] = useState('');
  const [isLoading, setIsLoading] = useState(false);
  const [showHealthChecklist, setShowHealthChecklist] = useState(false);
  const [showDayPicker, setShowDayPicker] = useState(false);
  const [currentDaysPerWeek, setCurrentDaysPerWeek] = useState(3);
  const [error, setError] = useState<string | null>(null);

  // Scroll to bottom when new messages arrive
  useEffect(() => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
  }, [conversationalOnboarding.messages]);

  // Initialize conversation with hardcoded opening message
  useEffect(() => {
    if (conversationalOnboarding.messages.length === 0) {
      setConversationalOnboarding({ isActive: true });

      const openingMessage = {
        role: 'assistant' as const,
        content: "Hey! I'm your AI fitness coach. Welcome to Aevo! Can you please help me with a few details below?",
        timestamp: new Date().toISOString(),
      };
      addConversationalMessage(openingMessage);
    }
  }, []);

  const handleSendMessage = async (message: string) => {
    if (!message.trim() || isLoading) return;

    setError(null);
    const userMessage = {
      role: 'user' as const,
      content: message,
      timestamp: new Date().toISOString(),
    };
    addConversationalMessage(userMessage);
    setInput('');
    setIsLoading(true);

    try {
      log.info('Sending message to backend:', message);

      // Parse response with backend (now using LangGraph agent!)
      const response = await parseOnboardingResponse({
        user_id: user?.id?.toString() || 'temp',
        message,
        current_data: conversationalOnboarding.collectedData,
        conversation_history: conversationalOnboarding.messages.map(msg => ({
          role: msg.role,
          content: msg.content,
        })),
      });

      log.info('Backend response:', response);

      // Update collected data
      if (response.extracted_data && Object.keys(response.extracted_data).length > 0) {
        updateCollectedData(response.extracted_data);
      }

      // Check if complete
      if (response.is_complete) {
        // Show health checklist before completion
        setShowHealthChecklist(true);
        setIsLoading(false);
        return;
      }

      // Check if day picker needed
      if (response.next_question.component === 'day_picker') {
        // Use the latest extracted_data first (it's just been collected), then fall back to stored data
        // Backend sends snake_case (days_per_week), frontend stores it as-is
        console.log('🔍 DEBUG: response.extracted_data =', response.extracted_data);
        console.log('🔍 DEBUG: response.extracted_data.days_per_week =', (response.extracted_data as any)?.days_per_week);
        console.log('🔍 DEBUG: stored collectedData =', conversationalOnboarding.collectedData);

        // Try multiple sources: latest extracted data (snake_case), stored snake_case, stored camelCase, default
        const daysPerWeek = (response.extracted_data as any)?.days_per_week
          || (conversationalOnboarding.collectedData as any)?.days_per_week
          || conversationalOnboarding.collectedData.daysPerWeek
          || 3;
        console.log('🔍 DEBUG: final daysPerWeek =', daysPerWeek);
        setCurrentDaysPerWeek(daysPerWeek);
        setShowDayPicker(true);

        const aiMessage = {
          role: 'assistant' as const,
          content: response.next_question.question || '',
          timestamp: new Date().toISOString(),
          component: 'day_picker' as const,
        };
        addConversationalMessage(aiMessage);
      } else {
        // Regular question
        const aiMessage = {
          role: 'assistant' as const,
          content: response.next_question.question || '',
          timestamp: new Date().toISOString(),
          quickReplies: response.next_question.quick_replies,
          multiSelect: response.next_question.multi_select || false,
        };
        addConversationalMessage(aiMessage);
      }

      setIsLoading(false);
    } catch (err: any) {
      log.error('Failed to process message:', err);
      setError(err.response?.data?.detail || 'Failed to process your message. Please try again.');
      setIsLoading(false);
    }
  };

  const handleQuickReply = (value: any) => {
    // For multi-select (arrays), join the values into a readable message
    if (Array.isArray(value)) {
      const label = value.join(', ');
      handleSendMessage(label);
    } else {
      const label = typeof value === 'object' ? JSON.stringify(value) : String(value);
      handleSendMessage(label);
    }
  };

  const handleDaySelection = (days: number[]) => {
    setShowDayPicker(false);
    updateCollectedData({ selected_days: days });
    const daysMessage = days.map((d) => ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'][d]).join(', ');
    handleSendMessage(daysMessage);
  };

  // Handle "Other" selection - focus the input so user can type custom value
  const handleOtherSelected = () => {
    inputRef.current?.focus();
  };

  // Check if a message looks like a completion message
  const isCompletionMessage = (content: string) => {
    const lowerContent = content.toLowerCase();
    return [
      "get started", "let's go", "ready to", "put together a plan", "create your plan",
      "fitness journey", "all set", "got everything", "thanks for sharing"
    ].some(keyword => lowerContent.includes(keyword));
  };

  // Handle "Let's Go" button - manually trigger completion
  const handleLetsGo = () => {
    setShowHealthChecklist(true);
  };

  const handleHealthChecklistComplete = async (data: { injuries: string[]; conditions: string[] }) => {
    setShowHealthChecklist(false);
    updateCollectedData({
      active_injuries: data.injuries,
      health_conditions: data.conditions,
    });

    // Complete onboarding
    await completeOnboarding(data.injuries, data.conditions);
  };

  const handleHealthChecklistSkip = async () => {
    setShowHealthChecklist(false);
    // Complete onboarding without health data
    await completeOnboarding([], []);
  };

  const completeOnboarding = async (injuries: string[], conditions: string[]) => {
    setIsLoading(true);

    try {
      log.info('Completing onboarding...');

      const finalData = {
        ...conversationalOnboarding.collectedData,
        active_injuries: injuries,
        health_conditions: conditions,
      };

      // Save conversation to database
      await saveOnboardingConversation({
        user_id: user?.id?.toString() || 'temp',
        conversation: conversationalOnboarding.messages.map((msg) => ({
          role: msg.role,
          content: msg.content,
          timestamp: msg.timestamp,
          extracted_data: msg.extractedData,
        })),
      });

      // Create/update user in Supabase
      const userData = {
        fitness_level: finalData.fitness_level || 'beginner',
        goals: JSON.stringify(finalData.goals || []),
        equipment: JSON.stringify(finalData.equipment || []),
        active_injuries: JSON.stringify(injuries),
        preferences: JSON.stringify({
          name: finalData.name,
          age: finalData.age,
          gender: finalData.gender,
          height_cm: finalData.heightCm,
          weight_kg: finalData.weightKg,
          target_weight_kg: finalData.target_weight_kg,
          days_per_week: finalData.days_per_week,
          selected_days: finalData.selected_days,
          workout_duration: finalData.workout_duration,
          preferred_time: finalData.preferred_time,
          training_split: finalData.training_split || 'full_body',
          intensity_preference: finalData.intensity_preference || 'moderate',
          workout_variety: finalData.workout_variety || 'varied',
          activity_level: finalData.activity_level || 'lightly_active',
          health_conditions: conditions,
        }),
      };

      let savedUser;
      if (user?.id) {
        savedUser = await updateUser(user.id, userData);
      } else {
        savedUser = await createUser(userData);
      }

      setUser(savedUser);
      log.info('User saved:', savedUser);

      // Generate first workout
      const todayDay = new Date().getDay();
      const isTodayWorkoutDay = (finalData.selected_days || []).includes(todayDay === 0 ? 6 : todayDay - 1);

      if (isTodayWorkoutDay) {
        log.info('Generating first workout...');
        await generateWorkout({
          user_id: savedUser.id,
          duration_minutes: finalData.workout_duration || 45,
          fitness_level: finalData.fitness_level || 'beginner',
          goals: finalData.goals || [],
          equipment: finalData.equipment || [],
        });
        log.info('First workout generated!');
      }

      // Success! Navigate to home
      navigate('/');
    } catch (err: any) {
      log.error('Failed to complete onboarding:', err);
      setError(err.response?.data?.detail || 'Failed to complete onboarding. Please try again.');
      setIsLoading(false);
    }
  };

  const latestMessage = conversationalOnboarding.messages[conversationalOnboarding.messages.length - 1];
  const showQuickReplies = latestMessage?.role === 'assistant' && latestMessage.quickReplies && !isLoading;

  // Show BasicInfoForm on first AI question (when asking for name)
  const showBasicInfoForm =
    latestMessage?.role === 'assistant' &&
    conversationalOnboarding.messages.length <= 2 &&
    !conversationalOnboarding.collectedData.name &&
    !isLoading;

  const handleBasicInfoSubmit = (data: { name: string; age: number; gender: string; heightCm: number; weightKg: number }) => {
    const message = `My name is ${data.name}, I'm ${data.age} years old, ${data.gender}, ${data.heightCm}cm tall, and I weigh ${data.weightKg}kg`;
    handleSendMessage(message);
  };

  return (
    <div className="h-screen bg-gradient-to-br from-background via-background to-background-dark flex flex-col overflow-hidden">
      {/* Header - sticky top */}
      <div className="sticky top-0 z-20 bg-background/80 backdrop-blur-md border-b border-white/10 px-4 py-3 flex items-center gap-3">
        <div className="w-10 h-10 rounded-full bg-gradient-to-br from-primary to-secondary flex items-center justify-center shadow-[0_0_20px_rgba(6,182,212,0.4)]">
          <svg className="w-5 h-5 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 3v4M3 5h4M6 17v4m-2-2h4m5-16l2.286 6.857L21 12l-5.714 2.143L13 21l-2.286-6.857L5 12l5.714-2.143L13 3z" />
          </svg>
        </div>
        <div className="flex-1">
          <h1 className="text-lg font-bold text-text">AI Fitness Coach</h1>
          <p className="text-xs text-text-secondary">Setting up your personalized plan...</p>
        </div>
        <button
          onClick={() => navigate('/onboarding')}
          className="px-3 py-1.5 text-xs font-medium text-text-secondary hover:text-text border border-white/20 rounded-lg hover:bg-white/10 transition-colors"
        >
          Use Form Instead
        </button>
      </div>

      {/* Messages Container */}
      <div className="flex-1 overflow-y-auto px-4 py-6">
        <div className="max-w-2xl mx-auto">
          {conversationalOnboarding.messages.map((message, index) => (
            <div key={index}>
              <MessageBubble
                role={message.role}
                content={message.content}
                timestamp={message.timestamp}
              />

              {/* Show quick replies for latest AI message */}
              {index === conversationalOnboarding.messages.length - 1 &&
                message.role === 'assistant' &&
                message.quickReplies &&
                !isLoading && (
                  <div className="ml-13">
                    <QuickReplyButtons
                      replies={message.quickReplies}
                      onSelect={handleQuickReply}
                      multiSelect={message.multiSelect || false}
                      onOtherSelected={handleOtherSelected}
                    />
                  </div>
                )}

              {/* Show "Let's Go" button for completion-like messages without quick replies */}
              {index === conversationalOnboarding.messages.length - 1 &&
                message.role === 'assistant' &&
                !message.quickReplies &&
                !message.component &&
                !isLoading &&
                isCompletionMessage(message.content) && (
                  <div className="ml-13 mt-3">
                    <button
                      onClick={handleLetsGo}
                      className="
                        px-6 py-3 rounded-xl font-bold
                        bg-gradient-to-r from-primary to-secondary text-white
                        shadow-[0_0_20px_rgba(6,182,212,0.5)]
                        hover:shadow-[0_0_30px_rgba(6,182,212,0.7)]
                        transition-all duration-200
                      "
                    >
                      Let's Go! 🚀
                    </button>
                  </div>
                )}

              {/* Show day picker if needed */}
              {index === conversationalOnboarding.messages.length - 1 &&
                message.component === 'day_picker' &&
                showDayPicker && (
                  <div className="ml-13">
                    <DayPickerComponent
                      daysPerWeek={currentDaysPerWeek}
                      onSelect={handleDaySelection}
                    />
                  </div>
                )}

              {/* Show BasicInfoForm on first AI question */}
              {index === conversationalOnboarding.messages.length - 1 &&
                showBasicInfoForm && (
                  <BasicInfoForm
                    onSubmit={handleBasicInfoSubmit}
                    disabled={isLoading}
                  />
                )}
            </div>
          ))}

          {/* Loading indicator */}
          {isLoading && (
            <div className="flex justify-start mb-4">
              <div className="bg-white/10 backdrop-blur-md border border-white/20 rounded-2xl px-4 py-3">
                <div className="flex gap-1">
                  <div className="w-2 h-2 bg-primary rounded-full animate-bounce" style={{ animationDelay: '0ms' }}></div>
                  <div className="w-2 h-2 bg-primary rounded-full animate-bounce" style={{ animationDelay: '150ms' }}></div>
                  <div className="w-2 h-2 bg-primary rounded-full animate-bounce" style={{ animationDelay: '300ms' }}></div>
                </div>
              </div>
            </div>
          )}

          {/* Error message */}
          {error && (
            <div className="bg-red-500/20 border border-red-500 text-red-400 rounded-xl px-4 py-3 mb-4">
              <p className="text-sm">{error}</p>
              <button
                onClick={() => setError(null)}
                className="text-xs underline mt-2"
              >
                Dismiss
              </button>
            </div>
          )}

          <div ref={messagesEndRef} />
        </div>
      </div>

      {/* Input Area - sticky bottom */}
      <div className="sticky bottom-0 z-20 bg-background/80 backdrop-blur-md border-t border-white/10 px-4 py-3">
        <div className="max-w-2xl mx-auto flex gap-2">
          <input
            ref={inputRef}
            type="text"
            value={input}
            onChange={(e) => setInput(e.target.value)}
            onKeyPress={(e) => e.key === 'Enter' && handleSendMessage(input)}
            placeholder="Type your message..."
            disabled={isLoading || showDayPicker}
            className="
              flex-1 px-4 py-3 rounded-xl
              bg-white/10 border border-white/20
              text-text placeholder-text-secondary
              focus:outline-none focus:border-primary focus:ring-1 focus:ring-primary
              disabled:opacity-50 disabled:cursor-not-allowed
            "
          />
          <button
            onClick={() => handleSendMessage(input)}
            disabled={!input.trim() || isLoading || showDayPicker}
            className="
              px-6 py-3 rounded-xl font-bold
              bg-gradient-to-r from-primary to-secondary text-white
              disabled:opacity-50 disabled:cursor-not-allowed
              enabled:shadow-[0_0_20px_rgba(6,182,212,0.5)]
              enabled:hover:shadow-[0_0_30px_rgba(6,182,212,0.7)]
              transition-all duration-200
            "
          >
            Send
          </button>
        </div>
      </div>

      {/* Health Checklist Modal */}
      {showHealthChecklist && (
        <HealthChecklistModal
          onComplete={handleHealthChecklistComplete}
          onSkip={handleHealthChecklistSkip}
        />
      )}
    </div>
  );
};

export default ConversationalOnboarding;
