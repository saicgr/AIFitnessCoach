import { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { DndContext, DragOverlay, closestCenter, useDraggable, useDroppable, MouseSensor, TouchSensor, useSensor, useSensors } from '@dnd-kit/core';
import type { DragEndEvent, DragStartEvent } from '@dnd-kit/core';
import { CSS } from '@dnd-kit/utilities';
import type { Workout } from '../types';
import {
  getWeekDates,
  formatWeekRange,
  toDateString,
  isToday as checkIsToday,
  isPastDate,
} from '../utils/dateUtils';
import { swapWorkout, deleteWorkout, regenerateWorkout, getWorkoutVersions, revertWorkout } from '../api/client';
import type { RegenerateWorkoutRequest, WorkoutVersionInfo } from '../api/client';
import { useMutation, useQueryClient } from '@tanstack/react-query';
import { useAppStore } from '../store';
import { DayCard, WorkoutCard, RestDayBadge } from './schedule';

interface WorkoutTimelineProps {
  workouts: Workout[];
  isLoading: boolean;
  onGenerateWorkout: () => void;
  isBackgroundGenerating?: boolean;
  onSelectWorkout?: (workoutId: string) => void;
  selectedWorkoutId?: string | null;
  compact?: boolean; // For 4-panel layout when exercise is selected
}

interface DraggableWorkoutCardProps {
  workout: Workout;
  isToday: boolean;
  isPast: boolean;
  isSelected?: boolean;
  onNavigate: (workoutId: string) => void;
  onDelete: (workoutId: string) => void;
  onStart: (workoutId: string) => void;
  onRegenerate: (workoutId: string) => void;
  onSettings: (workoutId: string) => void;
  isRegenerating?: boolean;
  compact?: boolean;
}

function DraggableWorkoutCard({ workout, isToday, isPast, isSelected, onNavigate, onDelete, onStart, onRegenerate, onSettings, isRegenerating, compact }: DraggableWorkoutCardProps) {
  const { attributes, listeners, setNodeRef, transform, isDragging } = useDraggable({
    id: workout.id,
    data: { workout },
  });

  const style = {
    transform: CSS.Translate.toString(transform),
  };

  // Handle click to navigate - only if not dragging
  const handleClick = () => {
    if (!isDragging) {
      onNavigate(workout.id);
    }
  };

  return (
    <div ref={setNodeRef} style={style} {...listeners} {...attributes}>
      <WorkoutCard
        workout={workout}
        isToday={isToday}
        isPast={isPast}
        isDragging={isDragging}
        isSelected={isSelected}
        onClick={handleClick}
        onDelete={onDelete}
        onStart={onStart}
        onRegenerate={onRegenerate}
        onSettings={onSettings}
        isRegenerating={isRegenerating}
        compact={compact}
      />
    </div>
  );
}

interface DroppableDayWrapperProps {
  dateString: string;
  children: React.ReactNode;
}

function DroppableDayWrapper({ dateString, children }: DroppableDayWrapperProps) {
  const { isOver, setNodeRef } = useDroppable({
    id: dateString,
    data: { date: dateString },
  });

  return (
    <div
      ref={setNodeRef}
      className={`flex-1 transition-all ${
        isOver ? 'ring-2 ring-primary ring-offset-2 ring-offset-background rounded-2xl' : ''
      }`}
    >
      {children}
    </div>
  );
}

interface ReasonModalProps {
  isOpen: boolean;
  onClose: () => void;
  onConfirm: (reason: string) => void;
  isLoading: boolean;
}

function ReasonModal({ isOpen, onClose, onConfirm, isLoading }: ReasonModalProps) {
  const [reason, setReason] = useState('');

  if (!isOpen) return null;

  const handleConfirm = () => {
    onConfirm(reason);
    setReason('');
  };

  const handleClose = () => {
    onClose();
    setReason('');
  };

  return (
    <div className="fixed inset-0 bg-black/70 backdrop-blur-sm flex items-center justify-center z-50 p-4">
      <div className="bg-surface border border-white/10 rounded-2xl p-6 max-w-md w-full shadow-xl">
        <h3 className="text-lg font-bold text-text mb-4">Why are you moving this workout?</h3>

        <textarea
          value={reason}
          onChange={(e) => setReason(e.target.value)}
          placeholder="e.g., I have a meeting on that day, feeling tired, etc."
          className="w-full p-3 bg-white/5 border border-white/10 rounded-xl mb-4 text-text placeholder:text-text-muted focus:ring-2 focus:ring-primary focus:border-primary resize-none"
          rows={3}
          autoFocus
        />

        <div className="flex gap-3 justify-end">
          <button
            onClick={handleClose}
            disabled={isLoading}
            className="px-4 py-2.5 bg-white/10 text-text-secondary rounded-xl font-semibold hover:bg-white/20 disabled:opacity-50 transition-all"
          >
            Cancel
          </button>
          <button
            onClick={handleConfirm}
            disabled={isLoading}
            className="px-4 py-2.5 bg-primary text-white rounded-xl font-semibold hover:bg-primary/80 disabled:opacity-50 transition-all"
          >
            {isLoading ? 'Moving...' : 'Move Workout'}
          </button>
        </div>
      </div>
    </div>
  );
}

interface DeleteConfirmModalProps {
  isOpen: boolean;
  workoutName: string;
  onClose: () => void;
  onConfirm: () => void;
  isLoading: boolean;
}

function DeleteConfirmModal({ isOpen, workoutName, onClose, onConfirm, isLoading }: DeleteConfirmModalProps) {
  if (!isOpen) return null;

  return (
    <div className="fixed inset-0 bg-black/70 backdrop-blur-sm flex items-center justify-center z-50 p-4">
      <div className="bg-surface border border-white/10 rounded-2xl p-6 max-w-md w-full shadow-xl">
        <div className="text-center mb-6">
          <div className="w-14 h-14 bg-coral/20 rounded-2xl flex items-center justify-center mx-auto mb-4">
            <svg className="w-7 h-7 text-coral" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" />
            </svg>
          </div>
          <h3 className="text-lg font-bold text-text">Delete Workout?</h3>
          <p className="text-text-secondary mt-2 text-sm">
            Are you sure you want to delete "{workoutName}"? This action cannot be undone.
          </p>
        </div>

        <div className="flex gap-3">
          <button
            onClick={onClose}
            disabled={isLoading}
            className="flex-1 px-4 py-3 bg-white/10 text-text-secondary rounded-xl font-semibold hover:bg-white/20 disabled:opacity-50 transition-all"
          >
            Cancel
          </button>
          <button
            onClick={onConfirm}
            disabled={isLoading}
            className="flex-1 px-4 py-3 bg-coral text-white rounded-xl font-semibold hover:bg-coral/80 disabled:opacity-50 transition-all"
          >
            {isLoading ? 'Deleting...' : 'Delete'}
          </button>
        </div>
      </div>
    </div>
  );
}

// Available equipment options
const EQUIPMENT_OPTIONS = [
  'barbell',
  'dumbbell',
  'kettlebell',
  'cable machine',
  'resistance bands',
  'pull-up bar',
  'bench',
  'bodyweight',
  'smith machine',
  'leg press',
  'lat pulldown',
  'rowing machine',
];

const DIFFICULTY_OPTIONS = ['easy', 'medium', 'hard'] as const;
type Difficulty = typeof DIFFICULTY_OPTIONS[number];

interface WorkoutSettingsModalProps {
  isOpen: boolean;
  workout: { id: string; duration_minutes: number; equipment?: string[]; difficulty?: string } | null;
  onClose: () => void;
  onSave: (settings: { duration_minutes: number; equipment: string[]; difficulty: string }) => void;
  onRevert: (workoutId: string, targetVersion: number) => void;
}

function WorkoutSettingsModal({ isOpen, workout, onClose, onSave, onRevert }: WorkoutSettingsModalProps) {
  const [duration, setDuration] = useState(45);
  const [selectedEquipment, setSelectedEquipment] = useState<string[]>([]);
  const [difficulty, setDifficulty] = useState<Difficulty>('medium');
  const [showCustomInput, setShowCustomInput] = useState(false);
  const [customEquipment, setCustomEquipment] = useState('');
  const [activeTab, setActiveTab] = useState<'settings' | 'history'>('settings');
  const [versions, setVersions] = useState<WorkoutVersionInfo[]>([]);
  const [isLoadingVersions, setIsLoadingVersions] = useState(false);
  const [isReverting, setIsReverting] = useState(false);

  // Update state when workout changes
  useEffect(() => {
    if (workout) {
      setDuration(workout.duration_minutes);
      setSelectedEquipment(workout.equipment || []);
      setDifficulty((workout.difficulty as Difficulty) || 'medium');
      setShowCustomInput(false);
      setCustomEquipment('');
      setActiveTab('settings');
      setVersions([]);
    }
  }, [workout]);

  // Load versions when switching to history tab
  useEffect(() => {
    if (activeTab === 'history' && workout && versions.length === 0) {
      setIsLoadingVersions(true);
      getWorkoutVersions(workout.id)
        .then(setVersions)
        .catch(() => setVersions([]))
        .finally(() => setIsLoadingVersions(false));
    }
  }, [activeTab, workout, versions.length]);

  if (!isOpen || !workout) return null;

  const handleRevert = async (targetVersion: number) => {
    if (!workout) return;
    setIsReverting(true);
    try {
      onRevert(workout.id, targetVersion);
      onClose();
    } finally {
      setIsReverting(false);
    }
  };

  const toggleEquipment = (eq: string) => {
    setSelectedEquipment(prev =>
      prev.includes(eq) ? prev.filter(e => e !== eq) : [...prev, eq]
    );
  };

  const addCustomEquipment = () => {
    const trimmed = customEquipment.trim().toLowerCase();
    if (trimmed && !selectedEquipment.includes(trimmed)) {
      setSelectedEquipment(prev => [...prev, trimmed]);
    }
    setCustomEquipment('');
    setShowCustomInput(false);
  };

  const handleSave = () => {
    onSave({ duration_minutes: duration, equipment: selectedEquipment, difficulty });
  };

  // Get custom equipment items (not in EQUIPMENT_OPTIONS)
  const customItems = selectedEquipment.filter(eq => !EQUIPMENT_OPTIONS.includes(eq));

  return (
    <div className="fixed inset-0 bg-black/70 backdrop-blur-sm flex items-center justify-center z-50 p-4">
      <div className="bg-surface border border-white/10 rounded-2xl p-6 max-w-md w-full shadow-xl max-h-[85vh] overflow-y-auto">
        <div className="flex items-center justify-between mb-5">
          <h3 className="text-lg font-bold text-text">Workout Settings</h3>
          <button
            onClick={onClose}
            className="p-2 rounded-xl hover:bg-white/10 transition-all"
          >
            <svg className="w-5 h-5 text-text-muted" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
            </svg>
          </button>
        </div>

        {/* Tab Navigation */}
        <div className="flex gap-2 mb-5 p-1 bg-white/5 rounded-xl">
          <button
            onClick={() => setActiveTab('settings')}
            className={`flex-1 px-4 py-2.5 rounded-lg text-sm font-medium transition-all ${
              activeTab === 'settings'
                ? 'bg-primary text-white shadow-lg shadow-primary/25'
                : 'text-text-secondary hover:text-text hover:bg-white/5'
            }`}
          >
            Settings
          </button>
          <button
            onClick={() => setActiveTab('history')}
            className={`flex-1 px-4 py-2.5 rounded-lg text-sm font-medium transition-all ${
              activeTab === 'history'
                ? 'bg-primary text-white shadow-lg shadow-primary/25'
                : 'text-text-secondary hover:text-text hover:bg-white/5'
            }`}
          >
            History
          </button>
        </div>

        {/* History Tab Content */}
        {activeTab === 'history' && (
          <div className="mb-5">
            {isLoadingVersions ? (
              <div className="flex items-center justify-center py-8">
                <svg className="w-6 h-6 text-primary animate-spin" fill="none" viewBox="0 0 24 24">
                  <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4" />
                  <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z" />
                </svg>
              </div>
            ) : versions.length <= 1 ? (
              <div className="text-center py-8 text-text-muted">
                <svg className="w-12 h-12 mx-auto mb-3 opacity-50" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z" />
                </svg>
                <p className="text-sm">No previous versions available.</p>
                <p className="text-xs mt-1 text-text-muted/70">Regenerate the workout to create a version history.</p>
              </div>
            ) : (
              <div className="space-y-2">
                {versions.map((version) => (
                  <div
                    key={version.id}
                    className={`p-4 rounded-xl border-2 transition-all ${
                      version.is_current
                        ? 'border-primary/40 bg-primary/10'
                        : 'border-white/10 bg-white/5 hover:border-white/20'
                    }`}
                  >
                    <div className="flex items-center justify-between">
                      <div>
                        <div className="flex items-center gap-2">
                          <span className="font-medium text-text">{version.name}</span>
                          {version.is_current && (
                            <span className="text-xs px-2 py-0.5 bg-primary/30 text-primary rounded-full font-medium">
                              Current
                            </span>
                          )}
                        </div>
                        <div className="text-xs text-text-muted mt-1 flex items-center gap-2">
                          <span>v{version.version_number}</span>
                          <span className="w-1 h-1 rounded-full bg-text-muted" />
                          <span>{version.exercises_count} exercises</span>
                          {version.valid_from && (
                            <>
                              <span className="w-1 h-1 rounded-full bg-text-muted" />
                              <span>{new Date(version.valid_from).toLocaleDateString()}</span>
                            </>
                          )}
                        </div>
                      </div>
                      {!version.is_current && (
                        <button
                          onClick={() => handleRevert(version.version_number)}
                          disabled={isReverting}
                          className="px-3 py-1.5 bg-accent/20 text-accent rounded-lg text-sm font-medium hover:bg-accent/30 transition-all disabled:opacity-50"
                        >
                          {isReverting ? 'Reverting...' : 'Restore'}
                        </button>
                      )}
                    </div>
                  </div>
                ))}
              </div>
            )}
          </div>
        )}

        {/* Settings Tab Content */}
        {activeTab === 'settings' && (
          <>
            {/* Duration Slider */}
            <div className="mb-6">
              <label className="block text-sm font-medium text-text mb-3">
                Duration: <span className="text-primary">{duration} minutes</span>
              </label>
              <input
                type="range"
                min="15"
                max="120"
                step="5"
                value={duration}
                onChange={(e) => setDuration(Number(e.target.value))}
                className="w-full h-2 bg-white/10 rounded-lg appearance-none cursor-pointer accent-primary"
              />
              <div className="flex justify-between text-xs text-text-muted mt-2">
                <span>15 min</span>
                <span>120 min</span>
              </div>
            </div>

            {/* Difficulty Selection */}
            <div className="mb-6">
              <label className="block text-sm font-medium text-text mb-3">
                Difficulty
              </label>
              <div className="flex gap-2">
                {DIFFICULTY_OPTIONS.map((level) => (
                  <button
                    key={level}
                    onClick={() => setDifficulty(level)}
                    className={`flex-1 px-3 py-2.5 rounded-xl text-sm font-medium transition-all capitalize ${
                      difficulty === level
                        ? level === 'easy' ? 'bg-emerald-500 text-white shadow-lg shadow-emerald-500/25'
                          : level === 'medium' ? 'bg-amber-500 text-white shadow-lg shadow-amber-500/25'
                          : 'bg-coral text-white shadow-lg shadow-coral/25'
                        : 'bg-white/5 text-text-secondary hover:bg-white/10'
                    }`}
                  >
                    {level}
                  </button>
                ))}
              </div>
            </div>

            {/* Equipment Selection */}
            <div className="mb-6">
              <label className="block text-sm font-medium text-text mb-3">
                Available Equipment
              </label>
              <div className="grid grid-cols-2 gap-2">
                {EQUIPMENT_OPTIONS.map((eq) => (
                  <button
                    key={eq}
                    onClick={() => toggleEquipment(eq)}
                    className={`px-3 py-2.5 rounded-xl text-sm font-medium transition-all capitalize ${
                      selectedEquipment.includes(eq)
                        ? 'bg-primary text-white shadow-lg shadow-primary/25'
                        : 'bg-white/5 text-text-secondary hover:bg-white/10'
                    }`}
                  >
                    {eq}
                  </button>
                ))}
              </div>

              {/* Custom equipment items */}
              {customItems.length > 0 && (
                <div className="mt-3 flex flex-wrap gap-2">
                  {customItems.map((eq) => (
                    <button
                      key={eq}
                      onClick={() => toggleEquipment(eq)}
                      className="px-3 py-1.5 rounded-lg text-sm font-medium bg-accent text-white flex items-center gap-1.5"
                    >
                      {eq}
                      <svg className="w-3.5 h-3.5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
                      </svg>
                    </button>
                  ))}
                </div>
              )}

              {/* Add custom equipment */}
              {showCustomInput ? (
                <div className="mt-3 flex gap-2">
                  <input
                    type="text"
                    value={customEquipment}
                    onChange={(e) => setCustomEquipment(e.target.value)}
                    onKeyDown={(e) => e.key === 'Enter' && addCustomEquipment()}
                    placeholder="e.g., medicine ball, TRX"
                    className="flex-1 px-3 py-2.5 bg-white/5 border border-white/10 rounded-xl text-text text-sm placeholder:text-text-muted focus:ring-2 focus:ring-primary focus:border-primary"
                    autoFocus
                  />
                  <button
                    onClick={addCustomEquipment}
                    className="px-4 py-2.5 bg-primary text-white rounded-xl text-sm font-medium"
                  >
                    Add
                  </button>
                  <button
                    onClick={() => { setShowCustomInput(false); setCustomEquipment(''); }}
                    className="px-4 py-2.5 bg-white/10 text-text-muted rounded-xl text-sm"
                  >
                    Cancel
                  </button>
                </div>
              ) : (
                <button
                  onClick={() => setShowCustomInput(true)}
                  className="mt-3 w-full py-2.5 border-2 border-dashed border-white/15 rounded-xl text-text-secondary hover:border-primary hover:text-primary transition-all flex items-center justify-center gap-2 text-sm"
                >
                  <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 4v16m8-8H4" />
                  </svg>
                  Add Other Equipment
                </button>
              )}
            </div>

            {/* Action Buttons */}
            <div className="flex gap-3">
              <button
                onClick={onClose}
                className="flex-1 px-4 py-3 bg-white/10 text-text-secondary rounded-xl font-semibold hover:bg-white/20 transition-all"
              >
                Cancel
              </button>
              <button
                onClick={handleSave}
                className="flex-1 px-4 py-3 bg-primary text-white rounded-xl font-semibold hover:bg-primary/80 transition-all shadow-lg shadow-primary/25"
              >
                Regenerate
              </button>
            </div>

            <p className="text-xs text-text-muted text-center mt-3">
              This will generate a new workout with these settings
            </p>
          </>
        )}
      </div>
    </div>
  );
}

export default function WorkoutTimeline({ workouts, isLoading, onGenerateWorkout, isBackgroundGenerating = false, onSelectWorkout, selectedWorkoutId, compact = false }: WorkoutTimelineProps) {
  const [weekOffset, setWeekOffset] = useState(0);
  const [activeWorkout, setActiveWorkout] = useState<Workout | null>(null);
  const [showReasonModal, setShowReasonModal] = useState(false);
  const [pendingSwap, setPendingSwap] = useState<{ workoutId: string; newDate: string } | null>(null);
  const [showDeleteModal, setShowDeleteModal] = useState(false);
  const [pendingDelete, setPendingDelete] = useState<{ workoutId: string; workoutName: string } | null>(null);
  const [regeneratingWorkoutId, setRegeneratingWorkoutId] = useState<string | null>(null);
  const [showSettingsModal, setShowSettingsModal] = useState(false);
  const [pendingSettings, setPendingSettings] = useState<{ workoutId: string; workout: Workout } | null>(null);

  const navigate = useNavigate();
  const queryClient = useQueryClient();
  const { user, setWorkouts } = useAppStore();

  // Configure sensors with delay for long-press to drag
  const mouseSensor = useSensor(MouseSensor, {
    activationConstraint: {
      delay: 300,
      tolerance: 5,
    },
  });

  const touchSensor = useSensor(TouchSensor, {
    activationConstraint: {
      delay: 300,
      tolerance: 5,
    },
  });

  const sensors = useSensors(mouseSensor, touchSensor);

  // Generate week dates (Monday to Sunday)
  const weekDates = getWeekDates(weekOffset);

  // Group workouts by date for quick lookup
  const workoutsByDate = new Map<string, Workout>();
  workouts.forEach((workout) => {
    if (workout.scheduled_date) {
      const dateKey = workout.scheduled_date.split('T')[0];
      if (!workoutsByDate.has(dateKey)) {
        workoutsByDate.set(dateKey, workout);
      }
    }
  });

  // Swap mutation
  const swapMutation = useMutation({
    mutationFn: async (params: { workout_id: string; new_date: string; reason?: string }) => {
      return await swapWorkout(params);
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['workouts', user?.id] });
      setShowReasonModal(false);
      setPendingSwap(null);
    },
    onError: (error: Error) => {
      console.error('Failed to swap workout:', error);
      alert('Failed to move workout. Please try again.');
    },
  });

  // Delete mutation
  const deleteMutation = useMutation({
    mutationFn: async (workoutId: string) => {
      return await deleteWorkout(workoutId);
    },
    onSuccess: (_, workoutId) => {
      const updatedWorkouts = workouts.filter(w => w.id !== workoutId);
      setWorkouts(updatedWorkouts);
      queryClient.invalidateQueries({ queryKey: ['workouts', user?.id] });
      setShowDeleteModal(false);
      setPendingDelete(null);
    },
    onError: (error: Error) => {
      console.error('Failed to delete workout:', error);
      alert('Failed to delete workout. Please try again.');
    },
  });

  // Regenerate mutation
  const regenerateMutation = useMutation({
    mutationFn: async (request: RegenerateWorkoutRequest) => {
      return await regenerateWorkout(request);
    },
    onSuccess: (newWorkout) => {
      const updatedWorkouts = workouts.filter(w => w.id !== regeneratingWorkoutId);
      updatedWorkouts.push(newWorkout);
      setWorkouts(updatedWorkouts);
      queryClient.invalidateQueries({ queryKey: ['workouts', user?.id] });
      setRegeneratingWorkoutId(null);
    },
    onError: (error: Error) => {
      console.error('Failed to regenerate workout:', error);
      alert('Failed to regenerate workout. Please try again.');
      setRegeneratingWorkoutId(null);
    },
  });

  // Revert mutation
  const revertMutation = useMutation({
    mutationFn: async ({ workoutId, targetVersion }: { workoutId: string; targetVersion: number }) => {
      return await revertWorkout({ workout_id: workoutId, target_version: targetVersion });
    },
    onSuccess: (newWorkout, { workoutId }) => {
      const updatedWorkouts = workouts.filter(w => w.id !== workoutId);
      updatedWorkouts.push(newWorkout);
      setWorkouts(updatedWorkouts);
      queryClient.invalidateQueries({ queryKey: ['workouts', user?.id] });
    },
    onError: (error: Error) => {
      console.error('Failed to revert workout:', error);
      alert('Failed to revert workout. Please try again.');
    },
  });

  // Navigation handler - use onSelectWorkout if provided (for desktop split view)
  const handleNavigate = (workoutId: string) => {
    if (onSelectWorkout) {
      onSelectWorkout(workoutId);
    } else {
      navigate(`/workout/${workoutId}`);
    }
  };

  // Start workout handler
  const handleStart = (workoutId: string) => {
    navigate(`/workout/${workoutId}?start=true`);
  };

  // Delete handler
  const handleDeleteRequest = (workoutId: string) => {
    const workout = workouts.find(w => w.id === workoutId);
    if (workout) {
      setPendingDelete({ workoutId, workoutName: workout.name });
      setShowDeleteModal(true);
    }
  };

  const handleDeleteConfirm = () => {
    if (pendingDelete) {
      deleteMutation.mutate(pendingDelete.workoutId);
    }
  };

  // Regenerate handler
  const handleRegenerateRequest = (workoutId: string) => {
    const workout = workouts.find(w => w.id === workoutId);
    if (workout && user) {
      setRegeneratingWorkoutId(workoutId);
      regenerateMutation.mutate({
        workout_id: workoutId,
        user_id: String(user.id),
        scheduled_date: workout.scheduled_date || new Date().toISOString(),
        duration_minutes: workout.duration_minutes,
        equipment: workout.equipment,
      });
    }
  };

  // Settings handler
  const handleSettingsRequest = (workoutId: string) => {
    const workout = workouts.find(w => w.id === workoutId);
    if (workout) {
      setPendingSettings({ workoutId, workout });
      setShowSettingsModal(true);
    }
  };

  const handleSettingsSave = (settings: { duration_minutes: number; equipment: string[]; difficulty: string }) => {
    if (pendingSettings && user) {
      const workoutId = pendingSettings.workoutId;
      const scheduledDate = pendingSettings.workout.scheduled_date || new Date().toISOString();

      setRegeneratingWorkoutId(workoutId);
      setShowSettingsModal(false);
      setPendingSettings(null);

      regenerateMutation.mutate({
        workout_id: workoutId,
        user_id: String(user.id),
        scheduled_date: scheduledDate,
        duration_minutes: settings.duration_minutes,
        equipment: settings.equipment,
        difficulty: settings.difficulty,
      });
    }
  };

  const handleRevert = (workoutId: string, targetVersion: number) => {
    revertMutation.mutate({ workoutId, targetVersion });
  };

  const handleDragStart = (event: DragStartEvent) => {
    const workout = workouts.find((w) => w.id === event.active.id);
    setActiveWorkout(workout || null);
  };

  const handleDragEnd = (event: DragEndEvent) => {
    const { active, over } = event;
    setActiveWorkout(null);

    if (!over || active.id === over.id) return;

    const newDate = over.id as string;
    const workoutId = active.id as string;

    const currentWorkout = workouts.find((w) => w.id === workoutId);
    if (currentWorkout?.scheduled_date?.split('T')[0] === newDate) {
      return;
    }

    setPendingSwap({ workoutId, newDate });
    setShowReasonModal(true);
  };

  const handleSwapConfirm = (reason: string) => {
    if (!pendingSwap) return;
    swapMutation.mutate({
      workout_id: pendingSwap.workoutId,
      new_date: pendingSwap.newDate,
      reason,
    });
  };

  const getWorkoutForDate = (date: Date): Workout | null => {
    const dateStr = toDateString(date);
    return workoutsByDate.get(dateStr) || null;
  };

  if (isLoading) {
    return (
      <div className="space-y-4">
        {[1, 2, 3, 4, 5, 6, 7].map((i) => (
          <div key={i} className="animate-pulse">
            <div className="flex gap-4 lg:gap-6">
              <div className="w-16 lg:w-20 flex-shrink-0">
                <div className="h-4 w-12 bg-white/10 rounded mb-1" />
                <div className="h-6 w-8 bg-white/10 rounded-lg" />
              </div>
              <div className="flex-1 h-24 bg-white/5 rounded-2xl" />
            </div>
          </div>
        ))}
      </div>
    );
  }

  return (
    <DndContext
      sensors={sensors}
      collisionDetection={closestCenter}
      onDragStart={handleDragStart}
      onDragEnd={handleDragEnd}
    >
      <div className="flex flex-col">
        {/* Week Navigation */}
        <div className="flex items-center justify-between mb-6 p-2 bg-white/5 rounded-xl">
          <button
            onClick={() => setWeekOffset((w) => w - 1)}
            className="p-2 hover:bg-white/10 rounded-lg transition-all"
            aria-label="Previous week"
          >
            <svg className="w-5 h-5 text-text-secondary" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 19l-7-7 7-7" />
            </svg>
          </button>

          <button
            onClick={() => setWeekOffset(0)}
            className={`px-4 py-2 rounded-lg text-sm font-semibold transition-all ${
              weekOffset === 0
                ? 'bg-primary/20 text-primary'
                : 'text-text-secondary hover:bg-white/10 hover:text-text'
            }`}
          >
            {formatWeekRange(weekDates)}
          </button>

          <button
            onClick={() => setWeekOffset((w) => w + 1)}
            className="p-2 hover:bg-white/10 rounded-lg transition-all"
            aria-label="Next week"
          >
            <svg className="w-5 h-5 text-text-secondary" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 5l7 7-7 7" />
            </svg>
          </button>
        </div>

        {/* Days List with Premium DayCard */}
        <div className="space-y-4">
          {weekDates.map((date) => {
            const workout = getWorkoutForDate(date);
            const isToday = checkIsToday(date);
            const isPast = isPastDate(date);
            const dateStr = toDateString(date);

            return (
              <DayCard key={dateStr} date={date} isToday={isToday} isPast={isPast}>
                <DroppableDayWrapper dateString={dateStr}>
                  {workout ? (
                    <DraggableWorkoutCard
                      workout={workout}
                      isToday={isToday}
                      isPast={isPast}
                      isSelected={selectedWorkoutId === workout.id}
                      onNavigate={handleNavigate}
                      onDelete={handleDeleteRequest}
                      onStart={handleStart}
                      onRegenerate={handleRegenerateRequest}
                      onSettings={handleSettingsRequest}
                      isRegenerating={regeneratingWorkoutId === workout.id}
                      compact={compact}
                    />
                  ) : (
                    <RestDayBadge
                      isToday={isToday}
                      isPast={isPast}
                      onAddWorkout={onGenerateWorkout}
                      isGenerating={isBackgroundGenerating}
                      compact={compact}
                    />
                  )}
                </DroppableDayWrapper>
              </DayCard>
            );
          })}
        </div>
      </div>

      {/* Drag Overlay */}
      <DragOverlay>
        {activeWorkout && (
          <div className="opacity-90">
            <WorkoutCard
              workout={activeWorkout}
              isToday={false}
              isPast={false}
              isDragging
            />
          </div>
        )}
      </DragOverlay>

      {/* Modals */}
      <ReasonModal
        isOpen={showReasonModal}
        onClose={() => {
          setShowReasonModal(false);
          setPendingSwap(null);
        }}
        onConfirm={handleSwapConfirm}
        isLoading={swapMutation.isPending}
      />

      <DeleteConfirmModal
        isOpen={showDeleteModal}
        workoutName={pendingDelete?.workoutName || ''}
        onClose={() => {
          setShowDeleteModal(false);
          setPendingDelete(null);
        }}
        onConfirm={handleDeleteConfirm}
        isLoading={deleteMutation.isPending}
      />

      <WorkoutSettingsModal
        isOpen={showSettingsModal}
        workout={pendingSettings?.workout ? {
          id: pendingSettings.workout.id,
          duration_minutes: pendingSettings.workout.duration_minutes,
          equipment: pendingSettings.workout.equipment,
          difficulty: pendingSettings.workout.difficulty
        } : null}
        onClose={() => {
          setShowSettingsModal(false);
          setPendingSettings(null);
        }}
        onSave={handleSettingsSave}
        onRevert={handleRevert}
      />
    </DndContext>
  );
}
