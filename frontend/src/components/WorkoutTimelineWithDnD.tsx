import { useState } from 'react';
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
  formatDuration
} from '../utils/dateUtils';
import { swapWorkout, deleteWorkout } from '../api/client';
import { useMutation, useQueryClient } from '@tanstack/react-query';
import { useAppStore } from '../store';

interface WorkoutTimelineProps {
  workouts: Workout[];
  isLoading: boolean;
  onGenerateWorkout: () => void;
  isBackgroundGenerating?: boolean;
}

interface WorkoutCardProps {
  workout: Workout;
  isToday: boolean;
  isPast: boolean;
  isDragging?: boolean;
  onClick?: () => void;
  onDelete?: (workoutId: string) => void;
}

function WorkoutCard({ workout, isToday, isPast, isDragging = false, onClick, onDelete }: WorkoutCardProps) {
  const isCompleted = !!workout.completed_at;

  const handleDeleteClick = (e: React.MouseEvent) => {
    e.stopPropagation();
    if (onDelete) {
      onDelete(workout.id);
    }
  };

  return (
    <div
      onClick={onClick}
      className={`group block p-4 rounded-xl border-2 transition-all hover:shadow-lg cursor-pointer ${
        isDragging ? 'opacity-50' : ''
      } ${
        isToday
          ? 'border-primary/50 bg-primary/10 shadow-[0_0_15px_rgba(6,182,212,0.15)]'
          : isCompleted
          ? 'border-accent/30 bg-accent/10'
          : isPast
          ? 'border-white/5 bg-white/5'
          : 'border-white/10 bg-white/5'
      }`}
    >
      <div className="flex items-center justify-between">
        <div className="flex-1 min-w-0">
          <h3 className="font-semibold text-text truncate">{workout.name}</h3>
          <p className="text-sm text-text-secondary mt-1 capitalize">{workout.type}</p>

          <div className="mt-2 flex items-center gap-3 text-xs text-text-muted">
            <span className="flex items-center gap-1">
              <svg className="w-3.5 h-3.5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z" />
              </svg>
              {formatDuration(workout.duration_minutes)}
            </span>
            <span>{workout.exercises.length} exercises</span>
            <span className="capitalize">{workout.difficulty}</span>
          </div>

          {/* Target Muscles */}
          {workout.target_muscles && workout.target_muscles.length > 0 && (
            <div className="mt-2 flex items-center gap-1.5 flex-wrap">
              <span className="text-text-muted text-xs mr-0.5">Targets:</span>
              {workout.target_muscles.slice(0, 3).map((muscle, idx) => (
                <span
                  key={idx}
                  className="px-2 py-0.5 bg-primary/20 text-primary text-xs rounded-full capitalize"
                >
                  {muscle}
                </span>
              ))}
              {workout.target_muscles.length > 3 && (
                <span className="text-xs text-text-muted">+{workout.target_muscles.length - 3}</span>
              )}
            </div>
          )}

          {/* Equipment */}
          {workout.equipment && workout.equipment.length > 0 && (
            <div className="mt-1.5 flex items-center gap-1.5 flex-wrap">
              <span className="text-text-muted text-xs mr-0.5">Equipment:</span>
              {workout.equipment.slice(0, 3).map((item, idx) => (
                <span
                  key={idx}
                  className="px-2 py-0.5 bg-accent/20 text-accent text-xs rounded-full capitalize"
                >
                  {item}
                </span>
              ))}
              {workout.equipment.length > 3 && (
                <span className="text-xs text-text-muted">+{workout.equipment.length - 3}</span>
              )}
            </div>
          )}
        </div>

        <div className="flex items-center gap-2">
          {/* Delete button - visible on hover */}
          {onDelete && !isDragging && (
            <button
              onClick={handleDeleteClick}
              className="p-1.5 rounded-full bg-coral/20 text-coral opacity-0 group-hover:opacity-100 hover:bg-coral/30 transition-all"
              title="Delete workout"
            >
              <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" />
              </svg>
            </button>
          )}

          {isCompleted ? (
            <div className="flex-shrink-0">
              <div className="w-8 h-8 rounded-full bg-accent flex items-center justify-center">
                <svg className="w-5 h-5 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 13l4 4L19 7" />
                </svg>
              </div>
            </div>
          ) : isPast && !isCompleted ? (
            <div className="flex-shrink-0">
              <div className="w-8 h-8 rounded-full bg-white/10 flex items-center justify-center">
                <svg className="w-4 h-4 text-text-muted" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
                </svg>
              </div>
            </div>
          ) : null}
        </div>
      </div>
    </div>
  );
}

interface DraggableWorkoutCardProps {
  workout: Workout;
  isToday: boolean;
  isPast: boolean;
  onNavigate: (workoutId: string) => void;
  onDelete: (workoutId: string) => void;
}

function DraggableWorkoutCard({ workout, isToday, isPast, onNavigate, onDelete }: DraggableWorkoutCardProps) {
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
        onClick={handleClick}
        onDelete={onDelete}
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
        isOver ? 'bg-primary/10 rounded-xl ring-2 ring-primary ring-offset-2' : ''
      }`}
    >
      {children}
    </div>
  );
}

interface RestDayCardProps {
  isToday: boolean;
  isPast: boolean;
  onAddWorkout: () => void;
  isGenerating?: boolean;
}

function RestDayCard({ isToday, isPast, onAddWorkout, isGenerating = false }: RestDayCardProps) {
  // Show generating placeholder if background generation is active and not a past date
  if (isGenerating && !isPast) {
    return (
      <div className="p-4 rounded-xl border-2 border-dashed border-primary/30 bg-primary/10 animate-pulse">
        <div className="flex items-center gap-2">
          <svg className="w-4 h-4 text-primary animate-spin" fill="none" viewBox="0 0 24 24">
            <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4" />
            <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z" />
          </svg>
          <span className="text-primary text-sm">Generating workout...</span>
        </div>
      </div>
    );
  }

  if (isToday) {
    return (
      <div className="p-4 rounded-xl border-2 border-dashed border-primary/30 bg-primary/10">
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-2">
            <svg className="w-5 h-5 text-primary/60" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M20 13V6a2 2 0 00-2-2H6a2 2 0 00-2 2v7m16 0v5a2 2 0 01-2 2H6a2 2 0 01-2-2v-5m16 0h-2.586a1 1 0 00-.707.293l-2.414 2.414a1 1 0 01-.707.293h-3.172a1 1 0 01-.707-.293l-2.414-2.414A1 1 0 006.586 13H4" />
            </svg>
            <span className="text-text-secondary font-medium">Rest Day</span>
          </div>
          <button
            onClick={onAddWorkout}
            className="text-primary text-sm font-medium hover:underline"
          >
            + Add Workout
          </button>
        </div>
      </div>
    );
  }

  return (
    <div className={`p-4 rounded-xl border-2 border-dashed ${
      isPast ? 'border-white/5 bg-white/5' : 'border-white/10 bg-white/5'
    }`}>
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-2">
          <svg className="w-5 h-5 text-text-muted" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M20 13V6a2 2 0 00-2-2H6a2 2 0 00-2 2v7m16 0v5a2 2 0 01-2 2H6a2 2 0 01-2-2v-5m16 0h-2.586a1 1 0 00-.707.293l-2.414 2.414a1 1 0 01-.707.293h-3.172a1 1 0 01-.707-.293l-2.414-2.414A1 1 0 006.586 13H4" />
          </svg>
          <span className="text-text-muted text-sm italic">
            {isPast ? 'Rest Day' : 'Rest Day'}
          </span>
        </div>
        {!isPast && (
          <button
            onClick={onAddWorkout}
            className="text-text-muted text-sm hover:text-primary transition-colors"
          >
            + Add
          </button>
        )}
      </div>
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
          className="w-full p-3 bg-white/5 border border-white/10 rounded-lg mb-4 text-text placeholder:text-text-muted focus:ring-2 focus:ring-primary focus:border-primary"
          rows={3}
          autoFocus
        />

        <div className="flex gap-3 justify-end">
          <button
            onClick={handleClose}
            disabled={isLoading}
            className="px-4 py-2 bg-white/10 text-text-secondary rounded-lg font-semibold hover:bg-white/20 disabled:opacity-50 transition-colors"
          >
            Cancel
          </button>
          <button
            onClick={handleConfirm}
            disabled={isLoading}
            className="px-4 py-2 bg-primary text-white rounded-lg font-semibold hover:bg-primary-dark disabled:opacity-50 transition-colors"
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
        <div className="text-center mb-4">
          <div className="w-12 h-12 bg-coral/20 rounded-full flex items-center justify-center mx-auto mb-3">
            <svg className="w-6 h-6 text-coral" fill="none" stroke="currentColor" viewBox="0 0 24 24">
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
            className="flex-1 px-4 py-3 bg-white/10 text-text-secondary rounded-xl font-semibold hover:bg-white/20 disabled:opacity-50 transition-colors"
          >
            Cancel
          </button>
          <button
            onClick={onConfirm}
            disabled={isLoading}
            className="flex-1 px-4 py-3 bg-coral text-white rounded-xl font-semibold hover:bg-coral/80 disabled:opacity-50 transition-colors"
          >
            {isLoading ? 'Deleting...' : 'Delete'}
          </button>
        </div>
      </div>
    </div>
  );
}

export default function WorkoutTimeline({ workouts, isLoading, onGenerateWorkout, isBackgroundGenerating = false }: WorkoutTimelineProps) {
  const [weekOffset, setWeekOffset] = useState(0);
  const [activeWorkout, setActiveWorkout] = useState<Workout | null>(null);
  const [showReasonModal, setShowReasonModal] = useState(false);
  const [pendingSwap, setPendingSwap] = useState<{ workoutId: string; newDate: string } | null>(null);
  const [showDeleteModal, setShowDeleteModal] = useState(false);
  const [pendingDelete, setPendingDelete] = useState<{ workoutId: string; workoutName: string } | null>(null);

  const navigate = useNavigate();
  const queryClient = useQueryClient();
  const { user, setWorkouts } = useAppStore();

  // Configure sensors with delay for long-press to drag
  const mouseSensor = useSensor(MouseSensor, {
    activationConstraint: {
      delay: 300,      // 300ms long-press required
      tolerance: 5,    // 5px movement tolerance
    },
  });

  const touchSensor = useSensor(TouchSensor, {
    activationConstraint: {
      delay: 300,      // 300ms long-press for mobile
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
      // Remove from local state
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

  // Navigation handler
  const handleNavigate = (workoutId: string) => {
    navigate(`/workout/${workoutId}`);
  };

  // Delete handler - shows confirmation modal
  const handleDeleteRequest = (workoutId: string) => {
    const workout = workouts.find(w => w.id === workoutId);
    if (workout) {
      setPendingDelete({ workoutId, workoutName: workout.name });
      setShowDeleteModal(true);
    }
  };

  // Confirm delete
  const handleDeleteConfirm = () => {
    if (pendingDelete) {
      deleteMutation.mutate(pendingDelete.workoutId);
    }
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

    // Don't allow moving to the same date
    const currentWorkout = workouts.find((w) => w.id === workoutId);
    if (currentWorkout?.scheduled_date?.split('T')[0] === newDate) {
      return;
    }

    // Show reason modal
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
      <div className="space-y-3">
        {[1, 2, 3, 4, 5, 6, 7].map((i) => (
          <div key={i} className="animate-pulse">
            <div className="flex gap-3">
              <div className="w-24 flex-shrink-0">
                <div className="h-4 w-16 bg-white/10 rounded mb-1" />
                <div className="h-3 w-12 bg-white/10 rounded" />
              </div>
              <div className="flex-1 h-20 bg-white/5 rounded-xl" />
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
        <div className="flex items-center justify-between p-4 mb-4 bg-white/5 rounded-xl border border-white/10">
          <button
            onClick={() => setWeekOffset((w) => w - 1)}
            className="p-2 hover:bg-white/10 rounded-lg transition-colors"
            aria-label="Previous week"
          >
            <svg className="w-5 h-5 text-text-secondary" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 19l-7-7 7-7" />
            </svg>
          </button>

          <div className="text-center">
            <div className="font-semibold text-text">{formatWeekRange(weekDates)}</div>
            {weekOffset === 0 && <div className="text-xs text-primary mt-0.5">Current Week</div>}
            <div className="text-xs text-text-muted mt-0.5">Long-press to drag</div>
          </div>

          <button
            onClick={() => setWeekOffset((w) => w + 1)}
            className="p-2 hover:bg-white/10 rounded-lg transition-colors"
            aria-label="Next week"
          >
            <svg className="w-5 h-5 text-text-secondary" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 5l7 7-7 7" />
            </svg>
          </button>
        </div>

        {/* Days List */}
        <div className="space-y-3">
          {weekDates.map((date) => {
            const workout = getWorkoutForDate(date);
            const isToday = checkIsToday(date);
            const isPast = isPastDate(date);
            const dateStr = toDateString(date);

            return (
              <div key={dateStr} className={`flex gap-3 ${isToday ? 'relative' : ''}`}>
                {/* Day Label */}
                <div className={`w-24 flex-shrink-0 ${isToday ? 'text-primary' : 'text-text-secondary'}`}>
                  <div className={`text-sm font-semibold ${isToday ? 'text-primary' : 'text-text'}`}>
                    {date.toLocaleDateString('en-US', { weekday: 'short' })}
                  </div>
                  <div className={`text-xs ${isToday ? 'text-primary' : 'text-text-muted'}`}>
                    {date.toLocaleDateString('en-US', { month: 'short', day: 'numeric' })}
                  </div>
                  {isToday && <div className="w-2 h-2 rounded-full bg-primary mt-1" />}
                </div>

                {/* Droppable Day Wrapper */}
                <DroppableDayWrapper dateString={dateStr}>
                  {workout ? (
                    <DraggableWorkoutCard
                      workout={workout}
                      isToday={isToday}
                      isPast={isPast}
                      onNavigate={handleNavigate}
                      onDelete={handleDeleteRequest}
                    />
                  ) : (
                    <RestDayCard
                      isToday={isToday}
                      isPast={isPast}
                      onAddWorkout={onGenerateWorkout}
                      isGenerating={isBackgroundGenerating}
                    />
                  )}
                </DroppableDayWrapper>
              </div>
            );
          })}
        </div>

        {/* Quick navigation buttons */}
        {weekOffset !== 0 && (
          <div className="mt-6 text-center">
            <button
              onClick={() => setWeekOffset(0)}
              className="text-sm text-primary font-medium hover:underline"
            >
              Back to Current Week
            </button>
          </div>
        )}
      </div>

      {/* Drag Overlay */}
      <DragOverlay>
        {activeWorkout && (
          <WorkoutCard
            workout={activeWorkout}
            isToday={false}
            isPast={false}
            isDragging
          />
        )}
      </DragOverlay>

      {/* Reason Modal */}
      <ReasonModal
        isOpen={showReasonModal}
        onClose={() => {
          setShowReasonModal(false);
          setPendingSwap(null);
        }}
        onConfirm={handleSwapConfirm}
        isLoading={swapMutation.isPending}
      />

      {/* Delete Confirmation Modal */}
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
    </DndContext>
  );
}
