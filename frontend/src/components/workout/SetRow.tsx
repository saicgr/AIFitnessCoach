import { useState, useRef, useEffect } from 'react';
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
  onSetFocus?: () => void;  // Called when user starts interacting with set
  isActive: boolean;
}

export default function SetRow({
  set,
  onWeightChange,
  onRepsChange,
  onComplete,
  onSetTypeChange,
  onSetFocus,
  isActive,
}: SetRowProps) {
  const weightRef = useRef<HTMLInputElement>(null);
  const repsRef = useRef<HTMLInputElement>(null);
  const [localWeight, setLocalWeight] = useState(set.actualWeight?.toString() ?? set.targetWeight.toString());
  const [localReps, setLocalReps] = useState(set.actualReps?.toString() ?? set.targetReps.toString());

  // Update local state when set changes (for previous workout data)
  useEffect(() => {
    setLocalWeight(set.actualWeight?.toString() ?? set.targetWeight.toString());
    setLocalReps(set.actualReps?.toString() ?? set.targetReps.toString());
  }, [set.actualWeight, set.actualReps, set.targetWeight, set.targetReps]);

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
      return 'bg-emerald-500/20 border-emerald-500/30';
    }
    if (set.setType === 'warmup') {
      return 'bg-amber-500/20 border-amber-500/30';
    }
    if (set.setType === 'failure') {
      return 'bg-red-500/20 border-red-500/30';
    }
    if (isActive) {
      return 'bg-white/10 border-primary/50';
    }
    return 'bg-white/5 border-white/10';
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

  return (
    <div
      className={`flex items-center gap-2 px-3 py-2 rounded-xl border transition-all duration-200 ${getRowStyles()}`}
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
            border border-white/20
            rounded-lg
            px-2 py-1.5
            text-center text-sm font-medium
            text-text
            placeholder:text-text-muted
            transition-all duration-200
            focus:outline-none focus:border-primary focus:ring-1 focus:ring-primary/30
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
            border border-white/20
            rounded-lg
            px-2 py-1.5
            text-center text-sm font-medium
            text-text
            placeholder:text-text-muted
            transition-all duration-200
            focus:outline-none focus:border-primary focus:ring-1 focus:ring-primary/30
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
          border-2 transition-all duration-200
          ${set.isCompleted
            ? 'bg-emerald-500 border-emerald-500 text-white cursor-default'
            : 'border-white/30 hover:border-primary hover:bg-primary/10 text-text-muted hover:text-primary'
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
  );
}
