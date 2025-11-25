import { useDraggable } from '@dnd-kit/core';
import { CSS } from '@dnd-kit/utilities';
import type { Workout } from '../types';
import TodayWorkoutCard from './TodayWorkoutCard';
import CompactWorkoutCard from './CompactWorkoutCard';

interface DraggableWorkoutProps {
  workout: Workout;
  isToday: boolean;
  isPast: boolean;
}

export default function DraggableWorkout({ workout, isToday, isPast }: DraggableWorkoutProps) {
  const { attributes, listeners, setNodeRef, transform, isDragging } = useDraggable({
    id: workout.id,
    data: {
      workout,
    },
  });

  const style = {
    transform: CSS.Translate.toString(transform),
    opacity: isDragging ? 0.5 : 1,
    cursor: 'grab',
  };

  return (
    <div ref={setNodeRef} style={style} {...listeners} {...attributes}>
      {isToday ? (
        <TodayWorkoutCard workout={workout} />
      ) : (
        <CompactWorkoutCard workout={workout} isPast={isPast} />
      )}
    </div>
  );
}
