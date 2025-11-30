import { useState } from 'react';

const FITNESS_LEVELS = [
  { id: 'beginner', label: 'Beginner', desc: 'New to fitness or returning after a break' },
  { id: 'intermediate', label: 'Intermediate', desc: 'Regular exercise for 6+ months' },
  { id: 'advanced', label: 'Advanced', desc: 'Consistent training for 2+ years' },
] as const;

const GOALS = [
  'Build Muscle',
  'Lose Weight',
  'Increase Strength',
  'Improve Endurance',
  'Stay Active',
  'Flexibility',
];

const EQUIPMENT = [
  'Bodyweight Only',
  'Dumbbells',
  'Barbell',
  'Resistance Bands',
  'Pull-up Bar',
  'Kettlebell',
  'Cable Machine',
  'Full Gym',
];

const DAYS_OF_WEEK = [
  { index: 0, name: 'Mon', fullName: 'Monday' },
  { index: 1, name: 'Tue', fullName: 'Tuesday' },
  { index: 2, name: 'Wed', fullName: 'Wednesday' },
  { index: 3, name: 'Thu', fullName: 'Thursday' },
  { index: 4, name: 'Fri', fullName: 'Friday' },
  { index: 5, name: 'Sat', fullName: 'Saturday' },
  { index: 6, name: 'Sun', fullName: 'Sunday' },
];

interface GenerateWorkoutModalProps {
  isOpen: boolean;
  onClose: () => void;
  onGenerate: (data: {
    fitnessLevel: string;
    goals: string[];
    equipment: string[];
    selectedDays: number[];
  }) => void;
  isGenerating: boolean;
  initialData?: {
    fitnessLevel: string;
    goals: string[];
    equipment: string[];
  };
}

export default function GenerateWorkoutModal({
  isOpen,
  onClose,
  onGenerate,
  isGenerating,
  initialData,
}: GenerateWorkoutModalProps) {
  const [step, setStep] = useState(0);
  const [fitnessLevel, setFitnessLevel] = useState(initialData?.fitnessLevel || 'beginner');
  const [goals, setGoals] = useState<string[]>(initialData?.goals || []);
  const [equipment, setEquipment] = useState<string[]>(initialData?.equipment || []);
  const [selectedDays, setSelectedDays] = useState<number[]>([]);

  if (!isOpen) return null;

  const toggleGoal = (goal: string) => {
    setGoals(goals.includes(goal) ? goals.filter((g) => g !== goal) : [...goals, goal]);
  };

  const toggleEquipment = (equip: string) => {
    setEquipment(equipment.includes(equip) ? equipment.filter((e) => e !== equip) : [...equipment, equip]);
  };

  const toggleDay = (dayIndex: number) => {
    setSelectedDays(selectedDays.includes(dayIndex)
      ? selectedDays.filter((d) => d !== dayIndex)
      : [...selectedDays, dayIndex].sort()
    );
  };

  const handleNext = () => {
    if (step < 3) {
      setStep(step + 1);
    } else {
      onGenerate({ fitnessLevel, goals, equipment, selectedDays });
    }
  };

  const handleBack = () => {
    if (step > 0) {
      setStep(step - 1);
    }
  };

  const canProceed = () => {
    if (step === 0) return true; // Fitness level always has a default
    if (step === 1) return goals.length > 0;
    if (step === 2) return equipment.length > 0;
    if (step === 3) return selectedDays.length > 0;
    return true;
  };

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center">
      {/* Backdrop */}
      <div
        className="absolute inset-0 bg-black/50 backdrop-blur-sm"
        onClick={isGenerating ? undefined : onClose}
      />

      {/* Modal */}
      <div className="relative bg-white rounded-2xl shadow-xl max-w-md w-full mx-4 p-6 max-h-[90vh] overflow-y-auto">
        {/* Loading Overlay */}
        {isGenerating && (
          <div className="absolute inset-0 bg-white/90 backdrop-blur-sm rounded-2xl flex flex-col items-center justify-center z-10">
            <div className="w-16 h-16 border-4 border-primary/20 border-t-primary rounded-full animate-spin mb-4" />
            <h3 className="text-lg font-semibold text-gray-900 mb-2">Generating Workouts</h3>
            <p className="text-sm text-gray-600 text-center px-4">
              Creating {selectedDays.length} personalized workout{selectedDays.length !== 1 ? 's' : ''}...
            </p>
            <p className="text-xs text-gray-400 mt-2">This may take 30-60 seconds</p>
          </div>
        )}

        {/* Close button */}
        <button
          onClick={onClose}
          disabled={isGenerating}
          className="absolute top-4 right-4 text-gray-400 hover:text-gray-600 disabled:opacity-50"
        >
          <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
          </svg>
        </button>

        {/* Progress */}
        <div className="flex gap-2 mb-6">
          {[0, 1, 2, 3].map((i) => (
            <div
              key={i}
              className={`h-2 flex-1 rounded-full transition-colors ${
                i <= step ? 'bg-primary' : 'bg-gray-200'
              }`}
            />
          ))}
        </div>

        {/* Step 0: Fitness Level */}
        {step === 0 && (
          <div className="space-y-4">
            <div>
              <h2 className="text-xl font-bold text-gray-900">Fitness Level</h2>
              <p className="text-gray-600 text-sm mt-1">What's your current fitness level?</p>
            </div>
            <div className="space-y-2">
              {FITNESS_LEVELS.map((level) => (
                <button
                  key={level.id}
                  onClick={() => setFitnessLevel(level.id)}
                  className={`w-full p-3 text-left rounded-lg border-2 transition-colors ${
                    fitnessLevel === level.id
                      ? 'border-primary bg-primary/5'
                      : 'border-gray-200 hover:border-gray-300'
                  }`}
                >
                  <div className="font-semibold text-gray-900">{level.label}</div>
                  <div className="text-xs text-gray-600">{level.desc}</div>
                </button>
              ))}
            </div>
          </div>
        )}

        {/* Step 1: Goals */}
        {step === 1 && (
          <div className="space-y-4">
            <div>
              <h2 className="text-xl font-bold text-gray-900">Your Goals</h2>
              <p className="text-gray-600 text-sm mt-1">Select all that apply</p>
            </div>
            <div className="flex flex-wrap gap-2">
              {GOALS.map((goal) => (
                <button
                  key={goal}
                  onClick={() => toggleGoal(goal)}
                  className={`px-3 py-2 rounded-full border-2 text-sm transition-colors ${
                    goals.includes(goal)
                      ? 'border-primary bg-primary text-white'
                      : 'border-gray-200 hover:border-gray-300'
                  }`}
                >
                  {goal}
                </button>
              ))}
            </div>
            {goals.length === 0 && (
              <p className="text-amber-600 text-sm">Please select at least one goal</p>
            )}
          </div>
        )}

        {/* Step 2: Equipment */}
        {step === 2 && (
          <div className="space-y-4">
            <div>
              <h2 className="text-xl font-bold text-gray-900">Equipment</h2>
              <p className="text-gray-600 text-sm mt-1">What equipment do you have access to?</p>
            </div>
            <div className="flex flex-wrap gap-2">
              {EQUIPMENT.map((equip) => (
                <button
                  key={equip}
                  onClick={() => toggleEquipment(equip)}
                  className={`px-3 py-2 rounded-full border-2 text-sm transition-colors ${
                    equipment.includes(equip)
                      ? 'border-secondary bg-secondary text-white'
                      : 'border-gray-200 hover:border-gray-300'
                  }`}
                >
                  {equip}
                </button>
              ))}
            </div>
            {equipment.length === 0 && (
              <p className="text-amber-600 text-sm">Please select at least one equipment option</p>
            )}
          </div>
        )}

        {/* Step 3: Select Days */}
        {step === 3 && (
          <div className="space-y-4">
            <div>
              <h2 className="text-xl font-bold text-gray-900">Workout Days</h2>
              <p className="text-gray-600 text-sm mt-1">Select which days you want to generate workouts for</p>
            </div>
            <div className="grid grid-cols-7 gap-2">
              {DAYS_OF_WEEK.map((day) => (
                <button
                  key={day.index}
                  onClick={() => toggleDay(day.index)}
                  className={`aspect-square rounded-lg border-2 text-sm font-semibold transition-all ${
                    selectedDays.includes(day.index)
                      ? 'border-primary bg-primary text-white shadow-md scale-105'
                      : 'border-gray-200 hover:border-gray-300 hover:bg-gray-50'
                  }`}
                  title={day.fullName}
                >
                  {day.name}
                </button>
              ))}
            </div>
            {selectedDays.length > 0 && (
              <div className="bg-primary/5 rounded-lg p-3 border border-primary/20">
                <p className="text-sm text-primary font-medium">
                  {selectedDays.length} workout{selectedDays.length !== 1 ? 's' : ''} will be generated
                </p>
                <p className="text-xs text-gray-600 mt-1">
                  {DAYS_OF_WEEK.filter(d => selectedDays.includes(d.index)).map(d => d.fullName).join(', ')}
                </p>
              </div>
            )}
            {selectedDays.length === 0 && (
              <p className="text-amber-600 text-sm">Please select at least one day</p>
            )}
          </div>
        )}

        {/* Navigation */}
        <div className="flex gap-3 mt-6">
          {step > 0 && (
            <button
              onClick={handleBack}
              disabled={isGenerating}
              className="flex-1 py-3 px-4 border border-gray-300 rounded-lg text-gray-700 hover:bg-gray-50 disabled:opacity-50"
            >
              Back
            </button>
          )}
          <button
            onClick={handleNext}
            disabled={!canProceed() || isGenerating}
            className="flex-1 py-3 px-4 bg-primary text-white rounded-lg hover:bg-primary-dark disabled:opacity-50 disabled:cursor-not-allowed"
          >
            {isGenerating
              ? 'Generating...'
              : step === 3
              ? `Generate ${selectedDays.length} Workout${selectedDays.length !== 1 ? 's' : ''}`
              : 'Next'}
          </button>
        </div>
      </div>
    </div>
  );
}
