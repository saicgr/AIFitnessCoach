import { useNavigate } from 'react-router-dom';
import { useQueryClient } from '@tanstack/react-query';
import type { CoachIntent } from '../../types';

interface ActionButton {
  label: string;
  action: () => void;
  primary?: boolean;
}

interface ChatActionsProps {
  intent: CoachIntent;
  actionData?: Record<string, unknown>;
  workoutId?: number;
}

export default function ChatActions({ intent, actionData, workoutId }: ChatActionsProps) {
  const navigate = useNavigate();
  const queryClient = useQueryClient();

  const getActions = (): ActionButton[] => {
    const targetWorkoutId = actionData?.workout_id as number || workoutId;

    switch (intent) {
      case 'question':
        if (targetWorkoutId) {
          return [
            {
              label: 'View Workout',
              action: () => navigate(`/workout/${targetWorkoutId}`),
            },
            {
              label: 'Start Workout',
              action: () => navigate(`/workout/${targetWorkoutId}/active`),
              primary: true,
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
          },
        ];

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

  return (
    <div className="flex flex-wrap gap-2 mt-3 pt-3 border-t border-gray-200">
      {actions.map((action, index) => (
        <button
          key={index}
          onClick={action.action}
          className={`px-4 py-2 rounded-lg text-sm font-medium transition-colors ${
            action.primary
              ? 'bg-primary text-white hover:bg-primary-dark'
              : 'bg-primary/10 text-primary hover:bg-primary/20'
          }`}
        >
          {action.label}
        </button>
      ))}
    </div>
  );
}
