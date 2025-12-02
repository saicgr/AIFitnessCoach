import { useState, useEffect } from 'react';
import type { WorkoutExercise } from '../types';
import { getExerciseFromLibraryByName } from '../api/client';

interface ExerciseInstructionsPanelProps {
  exercise: WorkoutExercise;
}

// Format notes to display numbered instructions on separate lines
function formatNotes(notes: string): string[] {
  if (!notes) return [];

  // Split on numbered patterns like "1.", "2.", "3." etc.
  // This regex matches patterns like "1.", "2.", "3." possibly with spaces
  const parts = notes.split(/(?=\d+\.\s)/);

  // Clean up and filter empty parts
  return parts
    .map(part => part.trim())
    .filter(part => part.length > 0);
}

export default function ExerciseInstructionsPanel({ exercise }: ExerciseInstructionsPanelProps) {
  const [fullInstructions, setFullInstructions] = useState<string | null>(null);
  const [isLoading, setIsLoading] = useState(false);

  // Always fetch full instructions from exercise library when panel opens
  // The workout exercise notes may be truncated, so we always try to get the full version
  useEffect(() => {
    const fetchFullInstructions = async () => {
      if (!exercise.name) return;

      setIsLoading(true);
      setFullInstructions(null); // Reset on exercise change

      try {
        const details = await getExerciseFromLibraryByName(exercise.name);
        if (details?.instructions) {
          // Use library instructions if they exist and are longer/more complete
          setFullInstructions(details.instructions);
        }
      } catch {
        // Silently fail - we'll just show the existing notes
      } finally {
        setIsLoading(false);
      }
    };

    fetchFullInstructions();
  }, [exercise.name]);

  // Use full instructions if available, otherwise fall back to exercise notes
  const displayNotes = fullInstructions || exercise.notes;

  return (
    <div className="h-full flex flex-col">
      {/* Header - Compact */}
      <div className="p-3 border-b border-white/10 flex-shrink-0">
        <div className="flex items-center gap-2">
          <div className="p-1.5 bg-secondary/20 rounded-lg text-secondary">
            <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
            </svg>
          </div>
          <div className="min-w-0">
            <h2 className="text-sm font-semibold text-text">Instructions</h2>
            <p className="text-xs text-text-secondary truncate">{exercise.name}</p>
          </div>
        </div>
      </div>

      {/* Instructions Content - Scrollable */}
      <div className="flex-1 overflow-y-auto p-3 space-y-2.5">
        {/* Compact Exercise Details - Single Row */}
        <div className="flex items-center gap-2 flex-wrap">
          <span className="px-2.5 py-1 bg-primary/15 text-primary text-sm font-semibold rounded-lg">
            {exercise.sets} × {exercise.reps}
          </span>
          {exercise.weight && (
            <span className="px-2.5 py-1 bg-accent/15 text-accent text-sm font-medium rounded-lg">
              {exercise.weight} lbs
            </span>
          )}
          <span className="px-2.5 py-1 bg-white/10 text-text-secondary text-sm rounded-lg">
            {exercise.rest_seconds}s rest
          </span>
          {exercise.muscle_group && (
            <span className="px-2.5 py-1 bg-secondary/15 text-secondary text-sm rounded-lg capitalize">
              {exercise.muscle_group}
            </span>
          )}
          {exercise.equipment && (
            <span className="px-2.5 py-1 bg-orange/15 text-orange text-sm rounded-lg capitalize">
              {exercise.equipment}
            </span>
          )}
        </div>

        {/* Notes/Instructions */}
        {displayNotes && (
          <div className="p-3 bg-white/5 rounded-xl border border-white/10">
            <h3 className="text-xs font-semibold text-text mb-1.5">Instructions</h3>
            {isLoading ? (
              <div className="text-text-secondary text-xs">Loading instructions...</div>
            ) : (
              <div className="text-text-secondary text-xs leading-relaxed space-y-1.5">
                {formatNotes(displayNotes).map((line, index) => (
                  <p key={index} className="leading-relaxed">{line}</p>
                ))}
              </div>
            )}
          </div>
        )}

        {/* Tips Section - Compact */}
        <div className="p-3 bg-gradient-to-br from-primary/10 to-secondary/10 rounded-xl border border-primary/20">
          <div className="flex items-center gap-2 mb-1.5">
            <svg className="w-3.5 h-3.5 text-primary" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
            </svg>
            <h3 className="text-xs font-semibold text-text">Tips</h3>
          </div>
          <ul className="text-text-secondary text-xs space-y-0.5">
            <li className="flex items-start gap-1.5">
              <span className="text-primary">•</span>
              <span>Focus on proper form over speed</span>
            </li>
            <li className="flex items-start gap-1.5">
              <span className="text-primary">•</span>
              <span>Breathe out during exertion</span>
            </li>
          </ul>
        </div>
      </div>
    </div>
  );
}
