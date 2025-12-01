import { useState, useRef, useEffect, useCallback } from 'react';
import type { ActiveSet } from '../../types';

// Format duration in MM:SS format
const formatSetDuration = (seconds: number): string => {
  const mins = Math.floor(seconds / 60);
  const secs = seconds % 60;
  return `${mins}:${secs.toString().padStart(2, '0')}`;
};

interface SetRowProps {
  set: ActiveSet;
  onWeightChange: (weight: number) => void;
  onRepsChange: (reps: number) => void;
  onComplete: () => void;
  onSetTypeChange?: (type: 'warmup' | 'working' | 'failure') => void;
  onSetFocus?: () => void;
  onDelete?: () => void;
  isActive: boolean;
}

const SWIPE_THRESHOLD = 80; // pixels to trigger delete
const DELETE_THRESHOLD = 150; // pixels to auto-delete

export default function SetRow({
  set,
  onWeightChange,
  onRepsChange,
  onComplete,
  onSetTypeChange,
  onSetFocus,
  onDelete,
  isActive,
}: SetRowProps) {
  const weightRef = useRef<HTMLInputElement>(null);
  const repsRef = useRef<HTMLInputElement>(null);
  const rowRef = useRef<HTMLDivElement>(null);
  const [localWeight, setLocalWeight] = useState(set.actualWeight?.toString() ?? set.targetWeight.toString());
  const [localReps, setLocalReps] = useState(set.actualReps?.toString() ?? set.targetReps.toString());

  // Swipe state
  const [swipeX, setSwipeX] = useState(0);
  const [isSwiping, setIsSwiping] = useState(false);
  const [showDeleteConfirm, setShowDeleteConfirm] = useState(false);
  const startXRef = useRef(0);
  const currentXRef = useRef(0);

  // Update local state when set changes (for previous workout data)
  useEffect(() => {
    setLocalWeight(set.actualWeight?.toString() ?? set.targetWeight.toString());
    setLocalReps(set.actualReps?.toString() ?? set.targetReps.toString());
  }, [set.actualWeight, set.actualReps, set.targetWeight, set.targetReps]);

  // Touch handlers for swipe-to-delete
  const handleTouchStart = useCallback((e: React.TouchEvent) => {
    if (!onDelete || set.isCompleted) return;
    startXRef.current = e.touches[0].clientX;
    currentXRef.current = e.touches[0].clientX;
    setIsSwiping(true);
  }, [onDelete, set.isCompleted]);

  const handleTouchMove = useCallback((e: React.TouchEvent) => {
    if (!isSwiping || !onDelete) return;
    currentXRef.current = e.touches[0].clientX;
    const diff = currentXRef.current - startXRef.current;
    // Only allow swiping right (positive diff)
    if (diff > 0) {
      setSwipeX(Math.min(diff, DELETE_THRESHOLD + 20));
    }
  }, [isSwiping, onDelete]);

  const handleTouchEnd = useCallback(() => {
    if (!isSwiping || !onDelete) return;
    setIsSwiping(false);

    if (swipeX >= DELETE_THRESHOLD) {
      // Auto-delete
      onDelete();
    } else if (swipeX >= SWIPE_THRESHOLD) {
      // Show delete confirmation
      setShowDeleteConfirm(true);
    } else {
      // Reset
      setSwipeX(0);
    }
  }, [isSwiping, swipeX, onDelete]);

  const handleDeleteConfirm = useCallback(() => {
    onDelete?.();
    setShowDeleteConfirm(false);
    setSwipeX(0);
  }, [onDelete]);

  const handleDeleteCancel = useCallback(() => {
    setShowDeleteConfirm(false);
    setSwipeX(0);
  }, []);

  const getSetLabel = () => {
    switch (set.setType) {
      case 'warmup':
        return 'W';
      case 'failure':
        return 'F';
      default:
        return set.setNumber.toString();
    }
  };

  const getRowStyles = () => {
    if (set.isCompleted) {
      return 'bg-emerald-500/15';
    }
    if (set.setType === 'warmup') {
      return 'bg-amber-500/15';
    }
    if (set.setType === 'failure') {
      return 'bg-red-500/15';
    }
    if (isActive) {
      return 'bg-white/10';
    }
    return 'bg-white/5';
  };

  const getSetLabelStyles = () => {
    if (set.setType === 'warmup') {
      return 'bg-amber-500/30 text-amber-300';
    }
    if (set.setType === 'failure') {
      return 'bg-red-500/30 text-red-300';
    }
    if (set.isCompleted) {
      return 'bg-emerald-500/30 text-emerald-300';
    }
    return 'bg-white/10 text-text-secondary';
  };

  const handleWeightBlur = () => {
    const weight = parseFloat(localWeight) || 0;
    onWeightChange(weight);
  };

  const handleRepsBlur = () => {
    const reps = parseInt(localReps) || 0;
    onRepsChange(reps);
  };

  const handleKeyDown = (e: React.KeyboardEvent, nextRef: React.RefObject<HTMLInputElement | null>) => {
    if (e.key === 'Enter') {
      e.preventDefault();
      if (nextRef.current) {
        nextRef.current.focus();
        nextRef.current.select();
      } else {
        // If no next ref, complete the set
        if (!set.isCompleted) {
          onComplete();
        }
      }
    }
  };

  const formatPrevious = () => {
    if (set.previousWeight !== undefined && set.previousReps !== undefined) {
      return `${set.previousWeight}kg×${set.previousReps}`;
    }
    return '-';
  };

  const handleSetTypeToggle = () => {
    if (!onSetTypeChange || set.isCompleted) return;

    const types: ('warmup' | 'working' | 'failure')[] = ['warmup', 'working', 'failure'];
    const currentIndex = types.indexOf(set.setType);
    const nextType = types[(currentIndex + 1) % types.length];
    onSetTypeChange(nextType);
  };

  // Calculate delete indicator opacity based on swipe distance
  const deleteOpacity = Math.min(swipeX / SWIPE_THRESHOLD, 1);

  return (
    <div className="relative overflow-hidden rounded-xl">
      {/* Delete background */}
      {onDelete && !set.isCompleted && (
        <div
          className="absolute inset-0 bg-red-500 flex items-center pl-4 rounded-xl"
          style={{ opacity: deleteOpacity }}
        >
          <svg className="w-6 h-6 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" />
          </svg>
          <span className="text-white font-medium ml-2">Delete</span>
        </div>
      )}

      {/* Main row content */}
      <div
        ref={rowRef}
        className={`flex items-center gap-2 px-3 py-2 rounded-xl transition-all duration-200 ${getRowStyles()} ${
          !isSwiping && swipeX === 0 ? '' : ''
        }`}
        style={{
          transform: `translateX(${swipeX}px)`,
          transition: isSwiping ? 'none' : 'transform 0.2s ease-out',
        }}
        onTouchStart={handleTouchStart}
        onTouchMove={handleTouchMove}
        onTouchEnd={handleTouchEnd}
      >
        {/* Set Number/Type */}
        <button
          onClick={handleSetTypeToggle}
          disabled={set.isCompleted}
          className={`w-8 h-8 rounded-lg flex items-center justify-center text-sm font-bold transition-colors ${getSetLabelStyles()} ${!set.isCompleted && onSetTypeChange ? 'cursor-pointer hover:opacity-80' : 'cursor-default'}`}
          title={!set.isCompleted ? 'Click to change set type' : undefined}
        >
          {getSetLabel()}
        </button>

        {/* Previous */}
        <div className="w-20 text-center text-sm text-text-muted">
          {formatPrevious()}
        </div>

        {/* Weight Input */}
        <div className="flex-1 max-w-20">
          <input
            ref={weightRef}
            type="number"
            inputMode="decimal"
            value={localWeight}
            onChange={(e) => setLocalWeight(e.target.value)}
            onBlur={handleWeightBlur}
            onKeyDown={(e) => handleKeyDown(e, repsRef)}
            onFocus={(e) => {
              e.target.select();
              onSetFocus?.();
            }}
            disabled={set.isCompleted}
            className={`
              w-full
              bg-white/10
              rounded-lg
              px-2 py-1.5
              text-center text-sm font-medium
              text-text
              placeholder:text-text-muted
              transition-all duration-200
              focus:outline-none focus:ring-1 focus:ring-primary/50
              disabled:opacity-60 disabled:cursor-not-allowed
              [appearance:textfield]
              [&::-webkit-outer-spin-button]:appearance-none
              [&::-webkit-inner-spin-button]:appearance-none
            `}
            placeholder="kg"
          />
        </div>

        {/* Reps Input */}
        <div className="flex-1 max-w-20">
          <input
            ref={repsRef}
            type="number"
            inputMode="numeric"
            value={localReps}
            onChange={(e) => setLocalReps(e.target.value)}
            onBlur={handleRepsBlur}
            onKeyDown={(e) => handleKeyDown(e, { current: null })}
            onFocus={(e) => {
              e.target.select();
              onSetFocus?.();
            }}
            disabled={set.isCompleted}
            className={`
              w-full
              bg-white/10
              rounded-lg
              px-2 py-1.5
              text-center text-sm font-medium
              text-text
              placeholder:text-text-muted
              transition-all duration-200
              focus:outline-none focus:ring-1 focus:ring-primary/50
              disabled:opacity-60 disabled:cursor-not-allowed
              [appearance:textfield]
              [&::-webkit-outer-spin-button]:appearance-none
              [&::-webkit-inner-spin-button]:appearance-none
            `}
            placeholder="reps"
          />
        </div>

        {/* Time Display */}
        <div className="w-14 text-center">
          {set.isCompleted && set.durationSeconds ? (
            <span className="text-emerald-400 font-mono text-sm">
              {formatSetDuration(set.durationSeconds)}
            </span>
          ) : set.startTime && !set.isCompleted ? (
            <span className="text-primary animate-pulse font-mono text-sm">
              ⏱️
            </span>
          ) : (
            <span className="text-text-muted text-sm">-</span>
          )}
        </div>

        {/* Complete Checkbox */}
        <button
          onClick={onComplete}
          disabled={set.isCompleted}
          className={`
            w-8 h-8 rounded-lg flex items-center justify-center
            transition-all duration-200
            ${set.isCompleted
              ? 'bg-emerald-500 text-white cursor-default'
              : 'bg-white/10 hover:bg-primary/20 text-text-muted hover:text-primary'
            }
          `}
        >
          {set.isCompleted ? (
            <svg className="w-5 h-5" fill="currentColor" viewBox="0 0 20 20">
              <path
                fillRule="evenodd"
                d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z"
                clipRule="evenodd"
              />
            </svg>
          ) : (
            <div className="w-3 h-3 rounded-sm border border-current" />
          )}
        </button>
      </div>

      {/* Delete confirmation overlay */}
      {showDeleteConfirm && (
        <div className="absolute inset-0 bg-surface/95 flex items-center justify-center gap-2 rounded-xl">
          <button
            onClick={handleDeleteConfirm}
            className="px-4 py-2 bg-red-500 text-white rounded-lg font-medium hover:bg-red-600 transition-colors"
          >
            Delete
          </button>
          <button
            onClick={handleDeleteCancel}
            className="px-4 py-2 bg-white/10 text-text rounded-lg font-medium hover:bg-white/20 transition-colors"
          >
            Cancel
          </button>
        </div>
      )}
    </div>
  );
}
