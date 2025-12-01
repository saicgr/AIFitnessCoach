/**
 * BasicInfoForm - Quick form for collecting Name, Age, Gender
 *
 * Shows below AI's first question to make onboarding faster.
 * Submits all three fields at once instead of 3 separate messages.
 */
import { useState, type FC } from 'react';
import { createLogger } from '../../utils/logger';

const log = createLogger('BasicInfoForm');

interface BasicInfoFormProps {
  onSubmit: (data: { name: string; age: number; gender: string; heightCm: number; weightKg: number }) => void;
  disabled?: boolean;
}

const BasicInfoForm: FC<BasicInfoFormProps> = ({ onSubmit, disabled = false }) => {
  const [name, setName] = useState('');
  const [age, setAge] = useState('');
  const [gender, setGender] = useState('');
  const [height, setHeight] = useState('');
  const [weight, setWeight] = useState('');
  const [heightUnit, setHeightUnit] = useState<'cm' | 'ft'>('cm');
  const [weightUnit, setWeightUnit] = useState<'kg' | 'lbs'>('kg');
  const [feet, setFeet] = useState('');
  const [inches, setInches] = useState('');

  const handleSubmit = () => {
    // Validate based on current unit system
    const isHeightValid = heightUnit === 'cm'
      ? height.trim() !== ''
      : feet.trim() !== '' && inches.trim() !== '';

    if (!name.trim() || !age || !gender || !isHeightValid || !weight) {
      log.warn('Form incomplete', { name, age, gender, height, weight, heightUnit });
      return;
    }

    const ageNum = parseInt(age);
    if (isNaN(ageNum) || ageNum < 13 || ageNum > 100) {
      log.warn('Invalid age', { age });
      return;
    }

    // Convert height to cm
    let heightCm: number;
    if (heightUnit === 'cm') {
      heightCm = parseFloat(height);
      if (isNaN(heightCm) || heightCm < 100 || heightCm > 250) {
        log.warn('Invalid height (cm)', { height });
        return;
      }
    } else {
      const feetNum = parseFloat(feet);
      const inchesNum = parseFloat(inches);
      if (isNaN(feetNum) || isNaN(inchesNum) || feetNum < 3 || feetNum > 8) {
        log.warn('Invalid height (ft/in)', { feet, inches });
        return;
      }
      // Convert ft + in to cm: (feet * 12 + inches) * 2.54
      heightCm = (feetNum * 12 + inchesNum) * 2.54;
    }

    // Convert weight to kg
    let weightKg: number;
    const weightNum = parseFloat(weight);
    if (isNaN(weightNum)) {
      log.warn('Invalid weight', { weight });
      return;
    }

    if (weightUnit === 'kg') {
      weightKg = weightNum;
      if (weightKg < 30 || weightKg > 300) {
        log.warn('Invalid weight (kg)', { weight });
        return;
      }
    } else {
      // Convert lbs to kg: lbs / 2.20462
      weightKg = weightNum / 2.20462;
      if (weightKg < 30 || weightKg > 300) {
        log.warn('Invalid weight (lbs)', { weight });
        return;
      }
    }

    log.info('Submitting basic info', { name, age: ageNum, gender, heightCm, weightKg });
    onSubmit({ name, age: ageNum, gender, heightCm: Math.round(heightCm), weightKg: Math.round(weightKg * 10) / 10 });
  };

  return (
    <div className="ml-13 mt-2 bg-white/5 backdrop-blur-md border border-white/10 rounded-2xl p-4">
      <p className="text-xs text-text-secondary mb-3">Quick info to get started</p>

      <div className="space-y-2">
        {/* Row 1: Name (full width) */}
        <div>
          <label className="text-xs text-text-secondary block mb-1">Name</label>
          <input
            type="text"
            value={name}
            onChange={(e) => setName(e.target.value)}
            placeholder="Your name"
            disabled={disabled}
            className="w-full px-3 py-2 rounded-lg bg-white/10 border border-white/20 text-text placeholder-text-secondary focus:outline-none focus:border-primary focus:ring-1 focus:ring-primary disabled:opacity-50 disabled:cursor-not-allowed text-sm"
          />
        </div>

        {/* Row 2: Age + Gender */}
        <div className="grid grid-cols-2 gap-2">
          <div>
            <label className="text-xs text-text-secondary block mb-1">Age</label>
            <input
              type="number"
              value={age}
              onChange={(e) => setAge(e.target.value)}
              placeholder="e.g., 25"
              min="13"
              max="100"
              disabled={disabled}
              className="w-full px-3 py-2 rounded-lg bg-white/10 border border-white/20 text-text placeholder-text-secondary focus:outline-none focus:border-primary focus:ring-1 focus:ring-primary disabled:opacity-50 disabled:cursor-not-allowed text-sm"
            />
          </div>
          <div>
            <label className="text-xs text-text-secondary block mb-1">Gender</label>
            <select
              value={gender}
              onChange={(e) => setGender(e.target.value)}
              disabled={disabled}
              className="w-full px-3 py-2 rounded-lg bg-white/10 border border-white/20 text-text focus:outline-none focus:border-primary focus:ring-1 focus:ring-primary disabled:opacity-50 disabled:cursor-not-allowed text-sm"
            >
              <option value="" className="bg-background text-text">Select</option>
              <option value="male" className="bg-background text-text">Male</option>
              <option value="female" className="bg-background text-text">Female</option>
              <option value="other" className="bg-background text-text">Other</option>
            </select>
          </div>
        </div>

        {/* Row 3: Height + Weight with unit toggles */}
        <div className="grid grid-cols-2 gap-2">
          {/* Height */}
          <div>
            <div className="flex items-center justify-between mb-1">
              <label className="text-xs text-text-secondary">Height</label>
              <div className="flex gap-0.5">
                <button
                  type="button"
                  onClick={() => setHeightUnit('cm')}
                  disabled={disabled}
                  className={`px-1.5 py-0.5 rounded text-xs ${heightUnit === 'cm' ? 'bg-primary text-white' : 'bg-white/10 text-text-secondary'}`}
                >
                  cm
                </button>
                <button
                  type="button"
                  onClick={() => setHeightUnit('ft')}
                  disabled={disabled}
                  className={`px-1.5 py-0.5 rounded text-xs ${heightUnit === 'ft' ? 'bg-primary text-white' : 'bg-white/10 text-text-secondary'}`}
                >
                  ft
                </button>
              </div>
            </div>
            {heightUnit === 'cm' ? (
              <input
                type="number"
                value={height}
                onChange={(e) => setHeight(e.target.value)}
                placeholder="170"
                min="100"
                max="250"
                disabled={disabled}
                className="w-full px-3 py-2 rounded-lg bg-white/10 border border-white/20 text-text placeholder-text-secondary focus:outline-none focus:border-primary focus:ring-1 focus:ring-primary disabled:opacity-50 disabled:cursor-not-allowed text-sm"
              />
            ) : (
              <div className="flex gap-1">
                <input
                  type="number"
                  value={feet}
                  onChange={(e) => setFeet(e.target.value)}
                  placeholder="5"
                  min="3"
                  max="8"
                  disabled={disabled}
                  className="w-full px-2 py-2 rounded-lg bg-white/10 border border-white/20 text-text placeholder-text-secondary focus:outline-none focus:border-primary focus:ring-1 focus:ring-primary disabled:opacity-50 disabled:cursor-not-allowed text-sm"
                />
                <span className="text-text-secondary self-center text-xs">'</span>
                <input
                  type="number"
                  value={inches}
                  onChange={(e) => setInches(e.target.value)}
                  placeholder="10"
                  min="0"
                  max="11"
                  disabled={disabled}
                  className="w-full px-2 py-2 rounded-lg bg-white/10 border border-white/20 text-text placeholder-text-secondary focus:outline-none focus:border-primary focus:ring-1 focus:ring-primary disabled:opacity-50 disabled:cursor-not-allowed text-sm"
                />
                <span className="text-text-secondary self-center text-xs">"</span>
              </div>
            )}
          </div>

          {/* Weight */}
          <div>
            <div className="flex items-center justify-between mb-1">
              <label className="text-xs text-text-secondary">Weight</label>
              <div className="flex gap-0.5">
                <button
                  type="button"
                  onClick={() => setWeightUnit('kg')}
                  disabled={disabled}
                  className={`px-1.5 py-0.5 rounded text-xs ${weightUnit === 'kg' ? 'bg-primary text-white' : 'bg-white/10 text-text-secondary'}`}
                >
                  kg
                </button>
                <button
                  type="button"
                  onClick={() => setWeightUnit('lbs')}
                  disabled={disabled}
                  className={`px-1.5 py-0.5 rounded text-xs ${weightUnit === 'lbs' ? 'bg-primary text-white' : 'bg-white/10 text-text-secondary'}`}
                >
                  lbs
                </button>
              </div>
            </div>
            <input
              type="number"
              value={weight}
              onChange={(e) => setWeight(e.target.value)}
              placeholder={weightUnit === 'kg' ? '70' : '154'}
              min={weightUnit === 'kg' ? '30' : '66'}
              max={weightUnit === 'kg' ? '300' : '660'}
              disabled={disabled}
              className="w-full px-3 py-2 rounded-lg bg-white/10 border border-white/20 text-text placeholder-text-secondary focus:outline-none focus:border-primary focus:ring-1 focus:ring-primary disabled:opacity-50 disabled:cursor-not-allowed text-sm"
            />
          </div>
        </div>

        {/* Submit Button */}
        <button
          onClick={handleSubmit}
          disabled={
            disabled ||
            !name.trim() ||
            !age ||
            !gender ||
            (heightUnit === 'cm' ? !height : (!feet || !inches)) ||
            !weight
          }
          className="
            w-full px-4 py-2 rounded-lg font-medium
            bg-gradient-to-r from-primary to-secondary text-white
            disabled:opacity-50 disabled:cursor-not-allowed
            enabled:shadow-[0_0_20px_rgba(6,182,212,0.3)]
            enabled:hover:shadow-[0_0_30px_rgba(6,182,212,0.5)]
            transition-all duration-200
            text-sm
          "
        >
          Continue
        </button>
      </div>
    </div>
  );
};

export default BasicInfoForm;
