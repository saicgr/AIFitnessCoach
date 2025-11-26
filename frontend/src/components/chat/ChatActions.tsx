import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { useQueryClient } from '@tanstack/react-query';
import { deleteWorkout } from '../../api/client';
import type { CoachIntent } from '../../types';

interface ActionButton {
  label: string;
  action: () => void;
  primary?: boolean;
  variant?: 'primary' | 'secondary' | 'danger';
}

interface ChatActionsProps {
  intent: CoachIntent;
  actionData?: Record<string, unknown>;
  workoutId?: number;
}

export default function ChatActions({ intent, actionData, workoutId }: ChatActionsProps) {
  const navigate = useNavigate();
  const queryClient = useQueryClient();
  const [isDeleting, setIsDeleting] = useState(false);
  const [deleteConfirmed, setDeleteConfirmed] = useState(false);

  const handleDeleteWorkout = async (workoutIdToDelete: number) => {
    setIsDeleting(true);
    try {
      await deleteWorkout(workoutIdToDelete);
      // Invalidate queries to refresh data
      queryClient.invalidateQueries({ queryKey: ['workouts'] });
      setDeleteConfirmed(true);
      // Navigate to home after deletion
      setTimeout(() => {
        navigate('/');
      }, 500);
    } catch (error) {
      console.error('Failed to delete workout:', error);
      setIsDeleting(false);
    }
  };

  const getActions = (): ActionButton[] => {
    const targetWorkoutId = actionData?.workout_id as number || workoutId;

    switch (intent) {
      case 'question':
        if (targetWorkoutId) {
          return [
            {
              label: 'View Workout',
              action: () => navigate(`/workout/${targetWorkoutId}`),
              variant: 'secondary',
            },
            {
              label: 'Start Workout',
              action: () => navigate(`/workout/${targetWorkoutId}/active`),
              primary: true,
              variant: 'primary',
            },
          ];
        }
        return [];

      case 'add_exercise':
      case 'remove_exercise':
      case 'modify_intensity':
        if (targetWorkoutId) {
          return [
            {
              label: 'View Updated Workout',
              action: () => {
                // Invalidate the workout cache to force a fresh fetch
                queryClient.invalidateQueries({ queryKey: ['workout', String(targetWorkoutId)] });
                queryClient.invalidateQueries({ queryKey: ['workouts'] });
                navigate(`/workout/${targetWorkoutId}`);
              },
              primary: true,
              variant: 'primary',
            },
          ];
        }
        return [];

      case 'swap_workout':
        const newWorkoutId = actionData?.new_workout_id as number || targetWorkoutId;
        if (newWorkoutId) {
          return [
            {
              label: 'View New Workout',
              action: () => navigate(`/workout/${newWorkoutId}`),
              primary: true,
              variant: 'primary',
            },
          ];
        }
        return [];

      case 'reschedule':
        return [
          {
            label: 'View Schedule',
            action: () => {
              // Invalidate workouts cache to show updated schedule
              queryClient.invalidateQueries({ queryKey: ['workouts'] });
              navigate('/');
            },
            primary: true,
            variant: 'primary',
          },
        ];

      case 'delete_workout':
        // Show confirmation buttons for delete
        if (targetWorkoutId && !deleteConfirmed) {
          return [
            {
              label: isDeleting ? 'Deleting...' : 'Confirm Delete',
              action: () => handleDeleteWorkout(targetWorkoutId),
              variant: 'danger',
            },
            {
              label: 'Keep Workout',
              action: () => {
                // Just navigate back to home without deleting
                navigate('/');
              },
              variant: 'secondary',
            },
          ];
        }
        if (deleteConfirmed) {
          return [
            {
              label: 'View Schedule',
              action: () => navigate('/'),
              primary: true,
              variant: 'primary',
            },
          ];
        }
        return [];

      case 'report_injury':
        // When user reports injury, AI modifies their workout - show button to view the updated workout
        if (targetWorkoutId) {
          return [
            {
              label: 'View Updated Workout',
              action: () => {
                queryClient.invalidateQueries({ queryKey: ['workout', String(targetWorkoutId)] });
                queryClient.invalidateQueries({ queryKey: ['workouts'] });
                navigate(`/workout/${targetWorkoutId}`);
              },
              primary: true,
              variant: 'primary',
            },
          ];
        }
        return [];

      default:
        return [];
    }
  };

  const actions = getActions();

  if (actions.length === 0) {
    return null;
  }

  const getButtonClasses = (action: ActionButton) => {
    const baseClasses = 'px-4 py-2 rounded-xl text-sm font-semibold transition-all duration-200';

    switch (action.variant) {
      case 'danger':
        return `${baseClasses} bg-coral text-white hover:bg-coral/80 shadow-[0_0_15px_rgba(244,63,94,0.3)]`;
      case 'secondary':
        return `${baseClasses} bg-white/10 text-text-secondary hover:bg-white/20 border border-white/10`;
      case 'primary':
      default:
        return `${baseClasses} bg-gradient-to-r from-primary to-primary-dark text-white hover:shadow-[0_0_20px_rgba(6,182,212,0.4)]`;
    }
  };

  return (
    <div className="flex flex-wrap gap-2 mt-3 pt-3 border-t border-white/10">
      {actions.map((action, index) => (
        <button
          key={index}
          onClick={action.action}
          disabled={isDeleting && action.variant === 'danger'}
          className={getButtonClasses(action)}
        >
          {action.label}
        </button>
      ))}
    </div>
  );
}
