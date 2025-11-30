/**
 * DayPickerComponent
 *
 * Interactive day selector for choosing workout days.
 * Shows M T W T F S S buttons with multi-select capability.
 *
 * Features:
 * - 7-day week grid
 * - Multi-select with visual feedback
 * - Validates against expected days_per_week
 * - Glass-morphism styling
 */
import { FC, useState, useEffect } from 'react';

interface DayPickerComponentProps {
  daysPerWeek: number;
  onSelect: (days: number[]) => void;
  initialSelected?: number[];
}

const DAYS = [
  { label: 'M', full: 'Monday', value: 0 },
  { label: 'T', full: 'Tuesday', value: 1 },
  { label: 'W', full: 'Wednesday', value: 2 },
  { label: 'T', full: 'Thursday', value: 3 },
  { label: 'F', full: 'Friday', value: 4 },
  { label: 'S', full: 'Saturday', value: 5 },
  { label: 'S', full: 'Sunday', value: 6 },
];

const DayPickerComponent: FC<DayPickerComponentProps> = ({
  daysPerWeek,
  onSelect,
  initialSelected = [],
}) => {
  const [selectedDays, setSelectedDays] = useState<Set<number>>(
    new Set(initialSelected)
  );

  useEffect(() => {
    setSelectedDays(new Set(initialSelected));
  }, [initialSelected]);

  const toggleDay = (dayValue: number) => {
    const newSelected = new Set(selectedDays);

    if (newSelected.has(dayValue)) {
      newSelected.delete(dayValue);
    } else {
      // Prevent selecting more than allowed
      if (newSelected.size < daysPerWeek) {
        newSelected.add(dayValue);
      }
    }

    setSelectedDays(newSelected);
  };

  const handleConfirm = () => {
    if (selectedDays.size === daysPerWeek) {
      onSelect(Array.from(selectedDays).sort());
    }
  };

  const isSelected = (value: number) => selectedDays.has(value);
  const canConfirm = selectedDays.size === daysPerWeek;

  return (
    <div className="mt-4 p-4 bg-white/5 backdrop-blur-sm border border-white/10 rounded-2xl">
      <p className="text-sm text-text-secondary mb-3">
        Select {daysPerWeek} days ({selectedDays.size}/{daysPerWeek} selected)
      </p>

      {/* Day Grid */}
      <div className="grid grid-cols-7 gap-2 mb-4">
        {DAYS.map((day) => (
          <button
            key={day.value}
            onClick={() => toggleDay(day.value)}
            disabled={!isSelected(day.value) && selectedDays.size >= daysPerWeek}
            className={`
              aspect-square rounded-xl text-sm font-bold
              transition-all duration-200
              ${
                isSelected(day.value)
                  ? 'bg-gradient-to-br from-primary to-secondary text-white shadow-[0_0_20px_rgba(6,182,212,0.5)] scale-110'
                  : selectedDays.size >= daysPerWeek
                  ? 'bg-white/5 text-text-secondary/50 cursor-not-allowed'
                  : 'bg-white/10 border border-white/20 text-text hover:bg-primary/20 hover:border-primary hover:scale-105'
              }
            `}
            title={day.full}
          >
            {day.label}
          </button>
        ))}
      </div>

      {/* Selected Days Preview */}
      {selectedDays.size > 0 && (
        <div className="text-xs text-text-secondary mb-3">
          Selected: {Array.from(selectedDays)
            .sort()
            .map((d) => DAYS[d].full)
            .join(', ')}
        </div>
      )}

      {/* Confirm Button */}
      <button
        onClick={handleConfirm}
        disabled={!canConfirm}
        className={`
          w-full px-4 py-2.5 rounded-xl text-sm font-bold
          transition-all duration-200
          ${
            canConfirm
              ? 'bg-gradient-to-r from-primary to-secondary text-white shadow-[0_0_20px_rgba(6,182,212,0.5)] hover:shadow-[0_0_30px_rgba(6,182,212,0.7)]'
              : 'bg-white/10 text-text-secondary/50 cursor-not-allowed'
          }
        `}
      >
        {canConfirm ? 'Confirm Days' : `Select ${daysPerWeek - selectedDays.size} more day${daysPerWeek - selectedDays.size !== 1 ? 's' : ''}`}
      </button>
    </div>
  );
};

export default DayPickerComponent;
