import { useState, useMemo } from 'react';
import { createPortal } from 'react-dom';
import { useQuery } from '@tanstack/react-query';
import { motion, AnimatePresence } from 'framer-motion';
import { getBodyParts, getLibraryExercises, type LibraryExercise } from '../api/client';

interface ExerciseWithConfig {
  exercise: LibraryExercise;
  sets: number;
  reps: number;
}

interface ExerciseLibraryModalProps {
  isOpen: boolean;
  onClose: () => void;
  onAddExercises: (exercises: ExerciseWithConfig[]) => void;
  existingExerciseNames?: string[];
}

export default function ExerciseLibraryModal({
  isOpen,
  onClose,
  onAddExercises,
  existingExerciseNames = [],
}: ExerciseLibraryModalProps) {
  const [searchQuery, setSearchQuery] = useState('');
  const [selectedBodyPart, setSelectedBodyPart] = useState<string | null>(null);
  const [selectedExercises, setSelectedExercises] = useState<Map<string, ExerciseWithConfig>>(new Map());
  const [configuring, setConfiguring] = useState<string | null>(null);
  const [tempSets, setTempSets] = useState(3);
  const [tempReps, setTempReps] = useState(10);

  // Fetch body parts
  const { data: bodyParts } = useQuery({
    queryKey: ['library', 'body-parts'],
    queryFn: getBodyParts,
  });

  // Fetch exercises
  const { data: exercises, isLoading } = useQuery({
    queryKey: ['library', 'exercises', selectedBodyPart, searchQuery],
    queryFn: () => getLibraryExercises({
      body_part: selectedBodyPart || undefined,
      search: searchQuery || undefined,
      limit: 100,
    }),
  });

  // Filter out already-existing exercises
  const filteredExercises = useMemo(() => {
    if (!exercises) return [];
    const existingSet = new Set(existingExerciseNames.map(n => n.toLowerCase()));
    return exercises.filter(ex => !existingSet.has(ex.name.toLowerCase()));
  }, [exercises, existingExerciseNames]);

  const handleToggleExercise = (exercise: LibraryExercise) => {
    const key = exercise.id;
    if (selectedExercises.has(key)) {
      const newMap = new Map(selectedExercises);
      newMap.delete(key);
      setSelectedExercises(newMap);
      setConfiguring(null);
    } else {
      // Show configuration for this exercise
      setConfiguring(key);
      setTempSets(3);
      setTempReps(10);
    }
  };

  const handleConfirmConfig = (exercise: LibraryExercise) => {
    const newMap = new Map(selectedExercises);
    newMap.set(exercise.id, {
      exercise,
      sets: tempSets,
      reps: tempReps,
    });
    setSelectedExercises(newMap);
    setConfiguring(null);
  };

  const handleAddSelected = () => {
    onAddExercises(Array.from(selectedExercises.values()));
    setSelectedExercises(new Map());
    setSearchQuery('');
    setSelectedBodyPart(null);
    onClose();
  };

  if (!isOpen) return null;

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
            <div className="px-5 py-4 border-b border-white/10 flex items-center justify-between">
              <div className="flex items-center gap-3">
                <div className="p-2 bg-primary/20 rounded-xl">
                  <svg className="w-5 h-5 text-primary" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 6v6m0 0v6m0-6h6m-6 0H6" />
                  </svg>
                </div>
                <div>
                  <h2 className="text-lg font-bold text-text">Add Exercises</h2>
                  <p className="text-xs text-text-secondary">
                    {selectedExercises.size > 0
                      ? `${selectedExercises.size} selected`
                      : 'Select exercises to add'}
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

            {/* Search and Filters */}
            <div className="px-5 py-3 border-b border-white/10 space-y-3">
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
                {bodyParts?.map((bp) => (
                  <button
                    key={bp.name}
                    onClick={() => setSelectedBodyPart(bp.name)}
                    className={`px-3 py-1.5 rounded-lg text-xs font-medium transition-colors capitalize ${
                      selectedBodyPart === bp.name
                        ? 'bg-primary text-white'
                        : 'bg-white/5 text-text-secondary hover:bg-white/10'
                    }`}
                  >
                    {bp.name} ({bp.count})
                  </button>
                ))}
              </div>
            </div>

            {/* Exercise List */}
            <div className="overflow-y-auto max-h-[calc(85vh-250px)] p-4">
              {isLoading ? (
                <div className="flex items-center justify-center py-12">
                  <div className="w-8 h-8 border-2 border-primary border-t-transparent rounded-full animate-spin" />
                </div>
              ) : filteredExercises.length === 0 ? (
                <div className="text-center py-12">
                  <p className="text-text-secondary">No exercises found</p>
                </div>
              ) : (
                <div className="grid grid-cols-1 gap-2">
                  {filteredExercises.map((exercise) => {
                    const isSelected = selectedExercises.has(exercise.id);
                    const isConfiguring = configuring === exercise.id;

                    return (
                      <div
                        key={exercise.id}
                        className={`p-3 rounded-xl border transition-all ${
                          isSelected
                            ? 'bg-primary/10 border-primary/50'
                            : 'bg-white/5 border-white/10 hover:border-white/20'
                        }`}
                      >
                        <div className="flex items-center justify-between">
                          <div
                            className="flex-1 cursor-pointer"
                            onClick={() => handleToggleExercise(exercise)}
                          >
                            <div className="flex items-center gap-3">
                              <div
                                className={`w-5 h-5 rounded border-2 flex items-center justify-center transition-colors ${
                                  isSelected
                                    ? 'bg-primary border-primary'
                                    : 'border-white/30'
                                }`}
                              >
                                {isSelected && (
                                  <svg className="w-3 h-3 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={3} d="M5 13l4 4L19 7" />
                                  </svg>
                                )}
                              </div>
                              <div>
                                <h3 className="font-medium text-text text-sm">{exercise.name}</h3>
                                <p className="text-xs text-text-muted capitalize">
                                  {exercise.body_part} {exercise.equipment && `• ${exercise.equipment}`}
                                </p>
                              </div>
                            </div>
                          </div>

                          {isSelected && (
                            <div className="flex items-center gap-2 text-xs text-text-secondary">
                              <span>{selectedExercises.get(exercise.id)?.sets} sets</span>
                              <span>x</span>
                              <span>{selectedExercises.get(exercise.id)?.reps} reps</span>
                            </div>
                          )}
                        </div>

                        {/* Configuration UI */}
                        {isConfiguring && (
                          <motion.div
                            initial={{ opacity: 0, height: 0 }}
                            animate={{ opacity: 1, height: 'auto' }}
                            exit={{ opacity: 0, height: 0 }}
                            className="mt-3 pt-3 border-t border-white/10"
                          >
                            <div className="flex items-center gap-4">
                              <div className="flex-1">
                                <label className="text-xs text-text-secondary mb-1 block">Sets</label>
                                <div className="flex items-center gap-2">
                                  <button
                                    onClick={() => setTempSets(Math.max(1, tempSets - 1))}
                                    className="w-8 h-8 bg-white/10 rounded-lg flex items-center justify-center text-text hover:bg-white/20"
                                  >
                                    -
                                  </button>
                                  <input
                                    type="number"
                                    value={tempSets}
                                    onChange={(e) => setTempSets(Math.max(1, parseInt(e.target.value) || 1))}
                                    className="w-12 text-center bg-white/10 rounded-lg py-1.5 text-text text-sm"
                                  />
                                  <button
                                    onClick={() => setTempSets(tempSets + 1)}
                                    className="w-8 h-8 bg-white/10 rounded-lg flex items-center justify-center text-text hover:bg-white/20"
                                  >
                                    +
                                  </button>
                                </div>
                              </div>

                              <div className="flex-1">
                                <label className="text-xs text-text-secondary mb-1 block">Reps</label>
                                <div className="flex items-center gap-2">
                                  <button
                                    onClick={() => setTempReps(Math.max(1, tempReps - 1))}
                                    className="w-8 h-8 bg-white/10 rounded-lg flex items-center justify-center text-text hover:bg-white/20"
                                  >
                                    -
                                  </button>
                                  <input
                                    type="number"
                                    value={tempReps}
                                    onChange={(e) => setTempReps(Math.max(1, parseInt(e.target.value) || 1))}
                                    className="w-12 text-center bg-white/10 rounded-lg py-1.5 text-text text-sm"
                                  />
                                  <button
                                    onClick={() => setTempReps(tempReps + 1)}
                                    className="w-8 h-8 bg-white/10 rounded-lg flex items-center justify-center text-text hover:bg-white/20"
                                  >
                                    +
                                  </button>
                                </div>
                              </div>

                              <button
                                onClick={() => handleConfirmConfig(exercise)}
                                className="px-4 py-2 bg-primary text-white rounded-lg text-sm font-medium hover:bg-primary/80 transition-colors mt-4"
                              >
                                Add
                              </button>
                            </div>
                          </motion.div>
                        )}
                      </div>
                    );
                  })}
                </div>
              )}
            </div>

            {/* Footer */}
            <div className="px-5 py-4 border-t border-white/10 flex items-center justify-between">
              <p className="text-xs text-text-muted">
                {filteredExercises.length} exercises available
              </p>
              <div className="flex gap-2">
                <button
                  onClick={onClose}
                  className="px-4 py-2 bg-white/10 text-text rounded-lg text-sm font-medium hover:bg-white/20 transition-colors"
                >
                  Cancel
                </button>
                <button
                  onClick={handleAddSelected}
                  disabled={selectedExercises.size === 0}
                  className="px-4 py-2 bg-primary text-white rounded-lg text-sm font-medium hover:bg-primary/80 transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
                >
                  Add {selectedExercises.size > 0 ? `(${selectedExercises.size})` : ''}
                </button>
              </div>
            </div>
          </motion.div>
        </>
      )}
    </AnimatePresence>,
    document.body
  );
}
