/**
 * ExerciseSwapModal
 *
 * Modal for swapping an exercise with another from the library.
 * Features:
 * - Browse exercise library with filters
 * - AI agent to get personalized suggestions based on current exercise
 * - Click to instantly swap
 * - All changes saved to database
 */
import { useState, useMemo, useEffect } from 'react';
import { createPortal } from 'react-dom';
import { useQuery } from '@tanstack/react-query';
import { motion, AnimatePresence } from 'framer-motion';
import {
  getBodyParts,
  getLibraryExercises,
  getExerciseSuggestions,
  type LibraryExercise,
  type ExerciseSuggestion,
} from '../api/client';
import { useAppStore } from '../store';
import type { WorkoutExercise } from '../types';

interface ExerciseSwapModalProps {
  isOpen: boolean;
  onClose: () => void;
  currentExercise: WorkoutExercise | null;
  onSwap: (newExercise: LibraryExercise, sets: number, reps: number) => void;
}

type Tab = 'browse' | 'ai';

export default function ExerciseSwapModal({
  isOpen,
  onClose,
  currentExercise,
  onSwap,
}: ExerciseSwapModalProps) {
  const user = useAppStore((s) => s.user);
  const onboardingData = useAppStore((s) => s.onboardingData);
  const [activeTab, setActiveTab] = useState<Tab>('browse');
  const [searchQuery, setSearchQuery] = useState('');
  const [selectedBodyPart, setSelectedBodyPart] = useState<string | null>(null);

  // AI Agent state
  const [chatMessages, setChatMessages] = useState<Array<{ role: 'user' | 'assistant'; content: string }>>([]);
  const [chatInput, setChatInput] = useState('');
  const [isAiLoading, setIsAiLoading] = useState(false);
  const [aiSuggestions, setAiSuggestions] = useState<ExerciseSuggestion[]>([]);

  // Reset state when modal opens
  useEffect(() => {
    if (isOpen && currentExercise) {
      setActiveTab('browse');
      setSearchQuery('');
      // Start with "All" selected - user can filter if they want
      setSelectedBodyPart(null);
      setChatMessages([]);
      setChatInput('');
      setAiSuggestions([]);
    }
  }, [isOpen, currentExercise]);

  // Fetch body parts
  const { data: bodyParts } = useQuery({
    queryKey: ['library', 'body-parts'],
    queryFn: getBodyParts,
    enabled: isOpen,
  });

  // Fetch exercises - get full library for browsing
  const { data: exercises, isLoading: exercisesLoading } = useQuery({
    queryKey: ['library', 'exercises', selectedBodyPart, searchQuery],
    queryFn: () => getLibraryExercises({
      body_part: selectedBodyPart || undefined,
      search: searchQuery || undefined,
      limit: 5000,  // Get full library
    }),
    enabled: isOpen,
  });

  // Filter out current exercise and exercises without videos
  const filteredExercises = useMemo(() => {
    if (!exercises || !currentExercise) return exercises || [];
    return exercises.filter(ex =>
      ex.name.toLowerCase() !== currentExercise.name.toLowerCase() &&
      ex.video_url  // Only show exercises that have videos
    );
  }, [exercises, currentExercise]);

  // Handle AI agent request
  const handleSendAiMessage = async () => {
    if (!chatInput.trim() || !user || !currentExercise) return;

    const userMessage = chatInput.trim();
    setChatInput('');
    setChatMessages(prev => [...prev, { role: 'user', content: userMessage }]);
    setIsAiLoading(true);
    setAiSuggestions([]);

    try {
      // Call the dedicated exercise suggestion agent
      const response = await getExerciseSuggestions({
        user_id: String(user.id),
        message: userMessage,
        current_exercise: {
          name: currentExercise.name,
          sets: currentExercise.sets,
          reps: currentExercise.reps,
          muscle_group: currentExercise.muscle_group,
          equipment: currentExercise.equipment,
        },
        user_equipment: onboardingData?.equipment,
        user_injuries: onboardingData?.activeInjuries,
        user_fitness_level: onboardingData?.fitnessLevel,
      });

      // Add AI response message
      setChatMessages(prev => [...prev, { role: 'assistant', content: response.message }]);

      // Set the suggestions for clickable buttons
      setAiSuggestions(response.suggestions);

    } catch (error) {
      console.error('AI agent error:', error);
      setChatMessages(prev => [...prev, {
        role: 'assistant',
        content: 'Sorry, I encountered an error getting suggestions. Please try again.'
      }]);
    } finally {
      setIsAiLoading(false);
    }
  };

  // Handle selecting an exercise to swap (from browse)
  const handleSelectExercise = (exercise: LibraryExercise) => {
    if (!currentExercise) return;
    onSwap(exercise, currentExercise.sets, currentExercise.reps);
    onClose();
  };

  // Handle clicking on an AI suggestion
  const handleAiSuggestionClick = async (suggestion: ExerciseSuggestion) => {
    if (!currentExercise) return;

    // If suggestion has an ID, it's from the library - find the full data
    if (suggestion.id) {
      const results = await getLibraryExercises({
        search: suggestion.name,
        limit: 5,
      });

      // Find exact match or close match
      const match = results.find(r =>
        r.name.toLowerCase() === suggestion.name.toLowerCase() ||
        r.id === suggestion.id
      ) || results[0];

      if (match) {
        handleSelectExercise(match);
        return;
      }
    }

    // Create a LibraryExercise from the suggestion
    const libraryExercise: LibraryExercise = {
      id: suggestion.id || `ai-${Date.now()}`,
      name: suggestion.name,
      original_name: suggestion.name,
      body_part: suggestion.body_part || currentExercise.muscle_group || 'unknown',
      equipment: suggestion.equipment,
      target_muscle: suggestion.target_muscle,
    };

    handleSelectExercise(libraryExercise);
  };

  if (!isOpen || !currentExercise) return null;

  return createPortal(
    <AnimatePresence>
      {isOpen && (
        <>
          {/* Backdrop */}
          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            className="fixed inset-0 bg-black/60 backdrop-blur-sm z-[9999]"
            onClick={onClose}
          />

          {/* Modal */}
          <motion.div
            initial={{ opacity: 0, scale: 0.95, y: 20 }}
            animate={{ opacity: 1, scale: 1, y: 0 }}
            exit={{ opacity: 0, scale: 0.95, y: 20 }}
            transition={{ type: 'spring', damping: 25, stiffness: 400 }}
            className="fixed z-[9999] top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-[95vw] max-w-2xl max-h-[85vh] overflow-hidden rounded-2xl bg-surface border border-white/10"
            style={{ boxShadow: '0 25px 50px -12px rgba(0,0,0,0.5)' }}
          >
            {/* Header */}
            <div className="px-5 py-4 border-b border-white/10">
              <div className="flex items-center justify-between">
                <div className="flex items-center gap-3">
                  <div className="p-2 bg-secondary/20 rounded-xl">
                    <svg className="w-5 h-5 text-secondary" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M8 7h12m0 0l-4-4m4 4l-4 4m0 6H4m0 0l4 4m-4-4l4-4" />
                    </svg>
                  </div>
                  <div>
                    <h2 className="text-lg font-bold text-text">Swap Exercise</h2>
                    <p className="text-xs text-text-secondary">
                      Replace "{currentExercise.name}"
                    </p>
                  </div>
                </div>
                <button
                  onClick={onClose}
                  className="p-2 hover:bg-white/10 rounded-lg transition-colors"
                >
                  <svg className="w-5 h-5 text-text-secondary" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
                  </svg>
                </button>
              </div>

              {/* Current Exercise Info */}
              <div className="mt-3 p-3 bg-white/5 rounded-xl flex items-center justify-between">
                <div>
                  <p className="text-sm text-text font-medium">{currentExercise.name}</p>
                  <p className="text-xs text-text-muted">
                    {currentExercise.sets} sets × {currentExercise.reps} reps
                    {currentExercise.muscle_group && ` • ${currentExercise.muscle_group}`}
                  </p>
                </div>
                <div className="text-xs text-text-muted px-2 py-1 bg-white/5 rounded">
                  Current
                </div>
              </div>

              {/* Tabs */}
              <div className="mt-4 flex gap-2">
                <button
                  onClick={() => setActiveTab('browse')}
                  className={`flex-1 px-4 py-2 rounded-lg text-sm font-medium transition-colors flex items-center justify-center gap-2 ${
                    activeTab === 'browse'
                      ? 'bg-primary text-white'
                      : 'bg-white/5 text-text-secondary hover:bg-white/10'
                  }`}
                >
                  <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
                  </svg>
                  Browse Library
                </button>
                <button
                  onClick={() => setActiveTab('ai')}
                  className={`flex-1 px-4 py-2 rounded-lg text-sm font-medium transition-colors flex items-center justify-center gap-2 ${
                    activeTab === 'ai'
                      ? 'bg-secondary text-white'
                      : 'bg-white/5 text-text-secondary hover:bg-white/10'
                  }`}
                >
                  <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9.663 17h4.673M12 3v1m6.364 1.636l-.707.707M21 12h-1M4 12H3m3.343-5.657l-.707-.707m2.828 9.9a5 5 0 117.072 0l-.548.547A3.374 3.374 0 0014 18.469V19a2 2 0 11-4 0v-.531c0-.895-.356-1.754-.988-2.386l-.548-.547z" />
                  </svg>
                  AI Agent
                </button>
              </div>
            </div>

            {/* Content */}
            <div className="overflow-y-auto max-h-[calc(85vh-280px)]">
              {activeTab === 'browse' ? (
                <div className="p-4">
                  {/* Search and Filters */}
                  <div className="space-y-3 mb-4">
                    {/* Search */}
                    <div className="relative">
                      <svg className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-text-muted" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
                      </svg>
                      <input
                        type="text"
                        value={searchQuery}
                        onChange={(e) => setSearchQuery(e.target.value)}
                        placeholder="Search exercises..."
                        className="w-full pl-10 pr-4 py-2 bg-white/5 border border-white/10 rounded-lg text-text placeholder-text-muted focus:outline-none focus:border-primary/50 text-sm"
                      />
                    </div>

                    {/* Body Part Filter */}
                    <div className="flex flex-wrap gap-1.5">
                      <button
                        onClick={() => setSelectedBodyPart(null)}
                        className={`px-3 py-1.5 rounded-lg text-xs font-medium transition-colors ${
                          selectedBodyPart === null
                            ? 'bg-primary text-white'
                            : 'bg-white/5 text-text-secondary hover:bg-white/10'
                        }`}
                      >
                        All
                      </button>
                      {bodyParts?.slice(0, 8).map((bp) => (
                        <button
                          key={bp.name}
                          onClick={() => setSelectedBodyPart(bp.name)}
                          className={`px-3 py-1.5 rounded-lg text-xs font-medium transition-colors capitalize ${
                            selectedBodyPart === bp.name
                              ? 'bg-primary text-white'
                              : 'bg-white/5 text-text-secondary hover:bg-white/10'
                          }`}
                        >
                          {bp.name}
                        </button>
                      ))}
                    </div>
                  </div>

                  {/* Exercise List */}
                  {exercisesLoading ? (
                    <div className="flex items-center justify-center py-12">
                      <div className="w-8 h-8 border-2 border-primary border-t-transparent rounded-full animate-spin" />
                    </div>
                  ) : filteredExercises.length === 0 ? (
                    <div className="text-center py-12">
                      <p className="text-text-secondary">No exercises found</p>
                    </div>
                  ) : (
                    <div className="grid grid-cols-1 gap-2">
                      {filteredExercises.map((exercise) => (
                        <motion.button
                          key={exercise.id}
                          onClick={() => handleSelectExercise(exercise)}
                          className="w-full p-3 rounded-xl border bg-white/5 border-white/10 hover:border-primary/50 hover:bg-primary/10 transition-all text-left group"
                          whileHover={{ scale: 1.01 }}
                          whileTap={{ scale: 0.99 }}
                        >
                          <div className="flex items-center justify-between">
                            <div>
                              <h3 className="font-medium text-text text-sm group-hover:text-primary transition-colors">
                                {exercise.name}
                              </h3>
                              <p className="text-xs text-text-muted capitalize">
                                {exercise.body_part} {exercise.equipment && `• ${exercise.equipment}`}
                              </p>
                            </div>
                            <svg className="w-5 h-5 text-text-muted group-hover:text-primary transition-colors" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M8 7h12m0 0l-4-4m4 4l-4 4m0 6H4m0 0l4 4m-4-4l4-4" />
                            </svg>
                          </div>
                        </motion.button>
                      ))}
                    </div>
                  )}
                </div>
              ) : (
                <div className="flex flex-col h-[calc(85vh-280px)]">
                  {/* Chat Messages */}
                  <div className="flex-1 overflow-y-auto p-4 space-y-3">
                    {chatMessages.length === 0 ? (
                      <div className="text-center py-8">
                        <div className="w-16 h-16 bg-secondary/20 rounded-2xl flex items-center justify-center mx-auto mb-4">
                          <svg className="w-8 h-8 text-secondary" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9.663 17h4.673M12 3v1m6.364 1.636l-.707.707M21 12h-1M4 12H3m3.343-5.657l-.707-.707m2.828 9.9a5 5 0 117.072 0l-.548.547A3.374 3.374 0 0014 18.469V19a2 2 0 11-4 0v-.531c0-.895-.356-1.754-.988-2.386l-.548-.547z" />
                          </svg>
                        </div>
                        <h3 className="text-text font-semibold mb-2">AI Exercise Agent</h3>
                        <p className="text-text-secondary text-sm max-w-xs mx-auto">
                          Tell me why you want to swap and I'll find the best alternatives from our library
                        </p>
                        <div className="mt-4 flex flex-wrap justify-center gap-2">
                          <button
                            onClick={() => setChatInput("I don't have the equipment for this exercise")}
                            className="px-3 py-1.5 bg-white/5 rounded-lg text-xs text-text-secondary hover:bg-white/10"
                          >
                            No equipment
                          </button>
                          <button
                            onClick={() => setChatInput("I want an easier alternative")}
                            className="px-3 py-1.5 bg-white/5 rounded-lg text-xs text-text-secondary hover:bg-white/10"
                          >
                            Easier option
                          </button>
                          <button
                            onClick={() => setChatInput("I have a shoulder injury")}
                            className="px-3 py-1.5 bg-white/5 rounded-lg text-xs text-text-secondary hover:bg-white/10"
                          >
                            Working around injury
                          </button>
                          <button
                            onClick={() => setChatInput("Give me some variety")}
                            className="px-3 py-1.5 bg-white/5 rounded-lg text-xs text-text-secondary hover:bg-white/10"
                          >
                            Just variety
                          </button>
                        </div>
                      </div>
                    ) : (
                      <>
                        {chatMessages.map((msg, idx) => (
                          <div
                            key={idx}
                            className={`flex ${msg.role === 'user' ? 'justify-end' : 'justify-start'}`}
                          >
                            <div
                              className={`max-w-[85%] p-3 rounded-xl text-sm ${
                                msg.role === 'user'
                                  ? 'bg-primary text-white'
                                  : 'bg-white/10 text-text'
                              }`}
                            >
                              <p className="whitespace-pre-wrap">{msg.content}</p>
                            </div>
                          </div>
                        ))}

                        {isAiLoading && (
                          <div className="flex justify-start">
                            <div className="bg-white/10 p-3 rounded-xl">
                              <div className="flex items-center gap-2">
                                <div className="w-2 h-2 bg-secondary rounded-full animate-bounce" />
                                <div className="w-2 h-2 bg-secondary rounded-full animate-bounce" style={{ animationDelay: '0.2s' }} />
                                <div className="w-2 h-2 bg-secondary rounded-full animate-bounce" style={{ animationDelay: '0.4s' }} />
                              </div>
                            </div>
                          </div>
                        )}

                        {/* AI Suggestions as clickable buttons */}
                        {aiSuggestions.length > 0 && (
                          <div className="mt-4 space-y-2">
                            <p className="text-xs text-text-muted font-semibold uppercase tracking-wider">
                              Click to swap:
                            </p>
                            {aiSuggestions.map((suggestion, idx) => (
                              <motion.button
                                key={idx}
                                onClick={() => handleAiSuggestionClick(suggestion)}
                                className={`w-full p-3 rounded-xl border transition-all text-left ${
                                  suggestion.rank === 1
                                    ? 'bg-green-500/15 border-green-500/40 hover:border-green-500/60 hover:bg-green-500/25'
                                    : 'bg-secondary/10 border-secondary/30 hover:border-secondary/50 hover:bg-secondary/20'
                                }`}
                                whileHover={{ scale: 1.01 }}
                                whileTap={{ scale: 0.99 }}
                              >
                                <div className="flex items-center justify-between">
                                  <div className="flex-1">
                                    <div className="flex items-center gap-2 flex-wrap">
                                      <h4 className="font-medium text-text text-sm">{suggestion.name}</h4>
                                      {suggestion.rank === 1 && (
                                        <span className="px-1.5 py-0.5 bg-green-500/30 text-green-400 rounded text-[10px] font-semibold">
                                          Best Match
                                        </span>
                                      )}
                                      {suggestion.rank === 2 && (
                                        <span className="px-1.5 py-0.5 bg-blue-500/20 text-blue-400 rounded text-[10px] font-medium">
                                          #2
                                        </span>
                                      )}
                                      {suggestion.rank === 3 && (
                                        <span className="px-1.5 py-0.5 bg-orange-500/20 text-orange-400 rounded text-[10px] font-medium">
                                          #3
                                        </span>
                                      )}
                                      {suggestion.body_part && (
                                        <span className="px-1.5 py-0.5 bg-white/10 rounded text-[10px] text-text-muted capitalize">
                                          {suggestion.body_part}
                                        </span>
                                      )}
                                    </div>
                                    <p className="text-xs text-text-muted mt-0.5">{suggestion.reason}</p>
                                    {suggestion.tip && (
                                      <p className="text-xs text-secondary/80 mt-1 italic">{suggestion.tip}</p>
                                    )}
                                  </div>
                                  <svg className={`w-5 h-5 flex-shrink-0 ml-2 ${suggestion.rank === 1 ? 'text-green-400' : 'text-secondary'}`} fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M8 7h12m0 0l-4-4m4 4l-4 4m0 6H4m0 0l4 4m-4-4l4-4" />
                                  </svg>
                                </div>
                              </motion.button>
                            ))}
                          </div>
                        )}
                      </>
                    )}
                  </div>

                  {/* Chat Input */}
                  <div className="p-4 border-t border-white/10">
                    <div className="flex gap-2">
                      <input
                        type="text"
                        value={chatInput}
                        onChange={(e) => setChatInput(e.target.value)}
                        onKeyDown={(e) => {
                          if (e.key === 'Enter' && !e.shiftKey) {
                            e.preventDefault();
                            handleSendAiMessage();
                          }
                        }}
                        placeholder="Tell me why you want to swap..."
                        className="flex-1 px-4 py-2 bg-white/5 border border-white/10 rounded-lg text-text placeholder-text-muted focus:outline-none focus:border-secondary/50 text-sm"
                        disabled={isAiLoading}
                      />
                      <button
                        onClick={handleSendAiMessage}
                        disabled={!chatInput.trim() || isAiLoading}
                        className="px-4 py-2 bg-secondary text-white rounded-lg text-sm font-medium hover:bg-secondary/80 transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
                      >
                        <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 19l9 2-9-18-9 18 9-2zm0 0v-8" />
                        </svg>
                      </button>
                    </div>
                  </div>
                </div>
              )}
            </div>
          </motion.div>
        </>
      )}
    </AnimatePresence>,
    document.body
  );
}
