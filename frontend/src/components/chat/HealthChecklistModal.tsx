/**
 * HealthChecklistModal Component
 *
 * Final safety check shown at the end of conversational onboarding.
 * Allows users to select injuries and health conditions (OPTIONAL).
 *
 * Features:
 * - Modal overlay with glass-morphism
 * - Two sections: Injuries and Health Conditions
 * - Optional - can skip entirely
 * - Multi-select with chips
 * - "None" is exclusive
 */
import { FC, useState } from 'react';

interface HealthChecklistModalProps {
  onComplete: (data: { injuries: string[]; conditions: string[] }) => void;
  onSkip: () => void;
}

const INJURY_OPTIONS = [
  'Lower back pain',
  'Shoulder issues',
  'Knee problems',
  'Wrist/elbow pain',
  'Neck pain',
  'Hip issues',
  'None',
];

const HEALTH_CONDITIONS = [
  'High blood pressure',
  'Heart condition',
  'Diabetes',
  'Asthma',
  'Arthritis',
  'Pregnancy',
  'Recent surgery',
  'None',
];

const HealthChecklistModal: FC<HealthChecklistModalProps> = ({
  onComplete,
  onSkip,
}) => {
  const [injuries, setInjuries] = useState<string[]>([]);
  const [conditions, setConditions] = useState<string[]>([]);

  const toggleItem = (
    item: string,
    currentList: string[],
    setList: (list: string[]) => void
  ) => {
    if (item === 'None') {
      // "None" is exclusive
      setList(currentList.includes('None') ? [] : ['None']);
    } else {
      // Remove "None" if selecting other items
      const newList = currentList.filter((i) => i !== 'None');
      if (newList.includes(item)) {
        setList(newList.filter((i) => i !== item));
      } else {
        setList([...newList, item]);
      }
    }
  };

  const handleComplete = () => {
    onComplete({
      injuries: injuries.includes('None') ? [] : injuries,
      conditions: conditions.includes('None') ? [] : conditions,
    });
  };

  return (
    <div className="fixed inset-0 bg-black/60 backdrop-blur-sm flex items-center justify-center z-50 p-4 animate-fade-in">
      <div className="bg-background/95 backdrop-blur-xl border border-white/20 rounded-3xl p-6 max-w-md w-full shadow-[0_0_50px_rgba(0,0,0,0.5)] max-h-[90vh] overflow-y-auto">
        {/* Header */}
        <div className="mb-6">
          <h2 className="text-2xl font-bold text-text mb-2">
            Health & Safety Check
          </h2>
          <p className="text-sm text-text-secondary">
            Help us keep your workouts safe. This is optional - skip if you prefer.
          </p>
        </div>

        {/* Injuries Section */}
        <div className="mb-6">
          <label className="text-sm font-medium text-text mb-3 block">
            Current Injuries or Pain
          </label>
          <div className="flex flex-wrap gap-2">
            {INJURY_OPTIONS.map((injury) => (
              <button
                key={injury}
                onClick={() => toggleItem(injury, injuries, setInjuries)}
                className={`
                  px-3 py-1.5 rounded-full text-xs font-medium
                  transition-all duration-200
                  ${
                    injury === 'None'
                      ? injuries.includes(injury)
                        ? 'bg-green-500/30 border-2 border-green-500 text-green-400'
                        : 'bg-white/10 border border-green-500/50 text-text-secondary'
                      : injuries.includes(injury)
                      ? 'bg-red-500/30 border-2 border-red-500 text-red-400'
                      : 'bg-white/10 border border-red-500/50 text-text-secondary'
                  }
                  hover:scale-105
                `}
              >
                {injury}
              </button>
            ))}
          </div>
        </div>

        {/* Health Conditions Section */}
        <div className="mb-6">
          <label className="text-sm font-medium text-text mb-3 block">
            Health Conditions
          </label>
          <div className="flex flex-wrap gap-2">
            {HEALTH_CONDITIONS.map((condition) => (
              <button
                key={condition}
                onClick={() => toggleItem(condition, conditions, setConditions)}
                className={`
                  px-3 py-1.5 rounded-full text-xs font-medium
                  transition-all duration-200
                  ${
                    condition === 'None'
                      ? conditions.includes(condition)
                        ? 'bg-green-500/30 border-2 border-green-500 text-green-400'
                        : 'bg-white/10 border border-green-500/50 text-text-secondary'
                      : conditions.includes(condition)
                      ? 'bg-orange-500/30 border-2 border-orange-500 text-orange-400'
                      : 'bg-white/10 border border-orange-500/50 text-text-secondary'
                  }
                  hover:scale-105
                `}
              >
                {condition}
              </button>
            ))}
          </div>
        </div>

        {/* Action Buttons */}
        <div className="flex gap-3">
          <button
            onClick={onSkip}
            className="
              flex-1 px-4 py-3 rounded-xl text-sm font-medium
              bg-white/10 border border-white/20 text-text-secondary
              hover:bg-white/20 hover:text-text
              transition-all duration-200
            "
          >
            Skip for now
          </button>
          <button
            onClick={handleComplete}
            className="
              flex-1 px-4 py-3 rounded-xl text-sm font-bold
              bg-gradient-to-r from-primary to-secondary text-white
              shadow-[0_0_20px_rgba(6,182,212,0.5)]
              hover:shadow-[0_0_30px_rgba(6,182,212,0.7)]
              transition-all duration-200
            "
          >
            Continue
          </button>
        </div>
      </div>
    </div>
  );
};

export default HealthChecklistModal;
