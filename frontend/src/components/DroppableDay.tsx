import { useDroppable } from '@dnd-kit/core';
import type { TimelineDay } from '../utils/dateUtils';

interface DroppableDayProps {
  day: TimelineDay;
  children: React.ReactNode;
}

export default function DroppableDay({ day, children }: DroppableDayProps) {
  const { isOver, setNodeRef } = useDroppable({
    id: day.dateString,
    data: {
      date: day.dateString,
      isToday: day.isToday,
      isPast: day.isPast,
    },
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
