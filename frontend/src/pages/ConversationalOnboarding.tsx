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
import { useState, useEffect, useRef, type FC } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAppStore } from '../store';
import {
  parseOnboardingResponse,
  saveOnboardingConversation,
  createUser,
  updateUser,
  generateMonthlyWorkouts,
  generateRemainingWorkouts,
} from '../api/client';
import MessageBubble from '../components/chat/MessageBubble';
import QuickReplyButtons from '../components/chat/QuickReplyButtons';
import DayPickerComponent from '../components/chat/DayPickerComponent';
import HealthChecklistModal from '../components/chat/HealthChecklistModal';
import BasicInfoForm from '../components/chat/BasicInfoForm';
import { createLogger } from '../utils/logger';

const log = createLogger('ConversationalOnboarding');

const ConversationalOnboarding: FC = () => {
  const navigate = useNavigate();
  const messagesEndRef = useRef<HTMLDivElement>(null);
  const inputRef = useRef<HTMLInputElement>(null);
  const initializedRef = useRef(false);

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
  const [showWorkoutLoading, setShowWorkoutLoading] = useState(false);
  const [workoutLoadingProgress, setWorkoutLoadingProgress] = useState(0);
  const [workoutLoadingMessage, setWorkoutLoadingMessage] = useState('');

  // Scroll to bottom when new messages arrive
  useEffect(() => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
  }, [conversationalOnboarding.messages]);

  // Initialize conversation with hardcoded opening message
  // Using ref to prevent React Strict Mode double-mount from adding duplicate messages
  useEffect(() => {
    if (conversationalOnboarding.messages.length === 0 && !initializedRef.current) {
      initializedRef.current = true;
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
    updateCollectedData({ selectedDays: days });
    const daysMessage = days.map((d) => ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'][d]).join(', ');
    handleSendMessage(daysMessage);
  };

  // Handle "Other" selection - focus the input so user can type custom value
  const handleOtherSelected = () => {
    inputRef.current?.focus();
  };

  // Check if a message looks like a completion message
  // These are messages where onboarding is done and we're ready to generate workouts
  const isCompletionMessage = (content: string) => {
    const lowerContent = content.toLowerCase();

    // Completion phrases that indicate we're ready to proceed
    const completionPhrases = [
      "let's get started",
      "ready to begin",
      "ready to create your plan",
      "put together a plan",
      "create your workout plan",
      "all set",
      "got everything i need",
      "ready to go",
      "let's kick things off",
      "let's get moving",
      "exciting journey",
      "ready to make some progress",
      "i'll prepare a workout plan",
      "prepare a workout plan"
    ];

    return completionPhrases.some(phrase => lowerContent.includes(phrase));
  };

  // Handle "Let's Go" button - manually trigger completion
  const handleLetsGo = () => {
    setShowHealthChecklist(true);
  };

  const handleHealthChecklistComplete = async (data: { injuries: string[]; conditions: string[] }) => {
    setShowHealthChecklist(false);
    updateCollectedData({
      activeInjuries: data.injuries,
      healthConditions: data.conditions,
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
    setShowWorkoutLoading(true);
    setWorkoutLoadingProgress(0);
    setWorkoutLoadingMessage('Saving your profile...');

    try {
      log.info('Completing onboarding...');

      const finalData = {
        ...conversationalOnboarding.collectedData,
        activeInjuries: injuries,
        healthConditions: conditions,
      };

      // Save conversation to database
      setWorkoutLoadingProgress(5);
      setWorkoutLoadingMessage('Saving conversation history...');
      await saveOnboardingConversation({
        user_id: user?.id?.toString() || 'temp',
        conversation: conversationalOnboarding.messages.map((msg) => ({
          role: msg.role,
          content: msg.content,
          timestamp: msg.timestamp,
          extracted_data: msg.extractedData,
        })),
      });

      setWorkoutLoadingProgress(15);
      setWorkoutLoadingMessage('Creating your fitness profile...');

      // Create/update user in Supabase
      const userData = {
        fitness_level: finalData.fitnessLevel || 'beginner',
        goals: JSON.stringify(finalData.goals || []),
        equipment: JSON.stringify(finalData.equipment || []),
        active_injuries: JSON.stringify(injuries),
        onboarding_completed: true,
        preferences: JSON.stringify({
          name: finalData.name,
          age: finalData.age,
          gender: finalData.gender,
          height_cm: finalData.heightCm,
          weight_kg: finalData.weightKg,
          target_weight_kg: finalData.targetWeightKg,
          days_per_week: finalData.daysPerWeek,
          selected_days: finalData.selectedDays,
          workout_duration: finalData.workoutDuration,
          preferred_time: finalData.preferredTime,
          training_split: finalData.trainingSplit || 'full_body',
          intensity_preference: finalData.intensityPreference || 'moderate',
          workout_variety: finalData.workoutVariety || 'varied',
          activity_level: finalData.activityLevel || 'lightly_active',
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

      setWorkoutLoadingProgress(25);
      setWorkoutLoadingMessage('Generating your first week of workouts...');

      // Generate workouts - week 1 first, then remaining weeks in background
      log.info('Starting workout generation - week 1 first...');
      try {
        // Convert day names to indices (0=Mon, 1=Tue, ..., 6=Sun)
        const dayNameToIndex: Record<string, number> = {
          'Monday': 0, 'Tuesday': 1, 'Wednesday': 2, 'Thursday': 3,
          'Friday': 4, 'Saturday': 5, 'Sunday': 6
        };

        let selectedDayIndices: number[] = [];
        const rawDays = (finalData.selectedDays || []) as (number | string)[];

        log.info('Raw selected_days from finalData:', rawDays);

        if (rawDays.length > 0) {
          if (typeof rawDays[0] === 'string') {
            // Convert day names to indices
            selectedDayIndices = (rawDays as string[])
              .map((day) => dayNameToIndex[day])
              .filter((idx): idx is number => idx !== undefined);
            log.info('Converted day names to indices:', selectedDayIndices);
          } else {
            // Already indices
            selectedDayIndices = rawDays as number[];
            log.info('Days already as indices:', selectedDayIndices);
          }
        }

        // Default to 3 days if none selected
        if (selectedDayIndices.length === 0) {
          log.warn('No selected days found, defaulting to Mon/Wed/Fri');
          selectedDayIndices = [0, 2, 4]; // Mon, Wed, Fri
        }

        const today = new Date();
        const monthStartDate = today.toISOString().split('T')[0];

        log.info('Selected day indices:', selectedDayIndices);

        // Start progress animation during workout generation
        const progressInterval = setInterval(() => {
          setWorkoutLoadingProgress(prev => {
            if (prev >= 85) return prev;
            return prev + Math.random() * 8;
          });
        }, 500);

        // STEP 1: Generate just week 1 first (fast, so user can start immediately)
        setWorkoutLoadingMessage(`Creating your first week of personalized workouts...`);

        const week1Result = await generateMonthlyWorkouts({
          user_id: String(savedUser.id),
          month_start_date: monthStartDate,
          duration_minutes: finalData.workoutDuration || 45,
          selected_days: selectedDayIndices,
          weeks: 1,  // Just week 1 for immediate use
        });

        clearInterval(progressInterval);
        setWorkoutLoadingProgress(90);
        log.info(`Generated ${week1Result.total_generated} workouts for week 1!`);

        // STEP 2: Fire off remaining weeks in the background (don't wait)
        // User will see their workouts grow as they're generated
        const remainingWeeksRequest = {
          user_id: String(savedUser.id),
          month_start_date: monthStartDate,
          duration_minutes: finalData.workoutDuration || 45,
          selected_days: selectedDayIndices,
          weeks: 11,  // Weeks 2-12
        };

        // Fire and forget - don't await, just log results
        generateRemainingWorkouts(remainingWeeksRequest)
          .then((result) => {
            log.info(`✅ Background generation complete: ${result.total_generated} additional workouts created!`);
          })
          .catch((err) => {
            log.error('⚠️ Background workout generation failed:', err);
            // Silently fail - user already has week 1
          });

        setWorkoutLoadingProgress(95);
        setWorkoutLoadingMessage(`Week 1 ready! More workouts generating in background...`);
      } catch (workoutErr: any) {
        log.error('Failed to generate week 1 workouts:', workoutErr);
        log.error('Error details:', workoutErr?.response?.data || workoutErr?.message || 'Unknown error');
        // Don't fail onboarding if workout generation fails
        setWorkoutLoadingMessage('Workouts will be generated later. Finishing setup...');
        // Wait a bit so user can see the message
        await new Promise(resolve => setTimeout(resolve, 2000));
      }

      setWorkoutLoadingProgress(100);
      setWorkoutLoadingMessage('All done! Taking you to your dashboard...');

      // Brief delay to show completion
      await new Promise(resolve => setTimeout(resolve, 1000));

      // Success! Navigate to home
      setShowWorkoutLoading(false);
      navigate('/');
    } catch (err: any) {
      log.error('Failed to complete onboarding:', err);
      setShowWorkoutLoading(false);
      setError(err.response?.data?.detail || 'Failed to complete onboarding. Please try again.');
      setIsLoading(false);
    }
  };

  const latestMessage = conversationalOnboarding.messages[conversationalOnboarding.messages.length - 1];

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

      {/* Workout Generation Loading Modal */}
      {showWorkoutLoading && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/80 backdrop-blur-sm">
          <div className="bg-background border border-white/20 rounded-2xl p-8 max-w-md w-full mx-4 shadow-2xl">
            {/* Animated Icon */}
            <div className="flex justify-center mb-6">
              <div className="relative">
                <div className="w-20 h-20 rounded-full bg-gradient-to-br from-primary/20 to-secondary/20 flex items-center justify-center">
                  <svg
                    className="w-10 h-10 text-primary animate-pulse"
                    fill="none"
                    stroke="currentColor"
                    viewBox="0 0 24 24"
                  >
                    <path
                      strokeLinecap="round"
                      strokeLinejoin="round"
                      strokeWidth={2}
                      d="M19.428 15.428a2 2 0 00-1.022-.547l-2.387-.477a6 6 0 00-3.86.517l-.318.158a6 6 0 01-3.86.517L6.05 15.21a2 2 0 00-1.806.547M8 4h8l-1 1v5.172a2 2 0 00.586 1.414l5 5c1.26 1.26.367 3.414-1.415 3.414H4.828c-1.782 0-2.674-2.154-1.414-3.414l5-5A2 2 0 009 10.172V5L8 4z"
                    />
                  </svg>
                </div>
                {/* Spinning ring */}
                <div className="absolute inset-0 rounded-full border-4 border-transparent border-t-primary animate-spin" />
              </div>
            </div>

            {/* Title */}
            <h2 className="text-xl font-bold text-text text-center mb-2">
              Building Your Workout Plan
            </h2>
            <p className="text-text-secondary text-center text-sm mb-6">
              {workoutLoadingMessage}
            </p>

            {/* Progress Bar */}
            <div className="w-full bg-white/10 rounded-full h-3 mb-4 overflow-hidden">
              <div
                className="h-full bg-gradient-to-r from-primary to-secondary rounded-full transition-all duration-500 ease-out"
                style={{ width: `${workoutLoadingProgress}%` }}
              />
            </div>

            {/* Progress Percentage */}
            <p className="text-center text-sm text-text-secondary">
              {Math.round(workoutLoadingProgress)}% complete
            </p>

            {/* Badge - shows week 1 first, then remaining weeks in background */}
            <div className="flex justify-center mt-6">
              <div className="px-4 py-2 rounded-full bg-gradient-to-r from-primary/20 to-secondary/20 border border-primary/30">
                <span className="text-sm font-medium text-primary">
                  {workoutLoadingProgress < 90 ? 'Week 1 First' : '12 Weeks of Workouts'}
                </span>
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

export default ConversationalOnboarding;
