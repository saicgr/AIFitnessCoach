import { useState, useEffect } from 'react';
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { motion, AnimatePresence } from 'framer-motion';
import {
  quickLogHydration,
  getDailyHydration,
  type DailyHydrationSummary,
} from '../../api/client';
import { useAppStore } from '../../store';

interface HydrationTrackerProps {
  userId: string;
  workoutId?: string;
  compact?: boolean;
}

type DrinkType = 'water' | 'protein_shake' | 'sports_drink';
type Unit = 'ml' | 'oz';

const DRINK_OPTIONS: { type: DrinkType; icon: string; color: string }[] = [
  { type: 'water', icon: '💧', color: 'from-blue-500 to-cyan-500' },
  { type: 'protein_shake', icon: '🥤', color: 'from-purple-500 to-pink-500' },
  { type: 'sports_drink', icon: '⚡', color: 'from-orange-500 to-yellow-500' },
];

// Default quick amounts in ml
const DEFAULT_AMOUNTS_ML = [250, 500, 750];

// Conversion helpers
const mlToOz = (ml: number) => Math.round(ml / 29.574);
const ozToMl = (oz: number) => Math.round(oz * 29.574);

const getAmountLabel = (ml: number, unit: Unit) => {
  if (unit === 'oz') {
    return `${mlToOz(ml)}oz`;
  }
  return `${ml}ml`;
};

// Load quick amounts from localStorage
const loadQuickAmounts = (): number[] => {
  try {
    const saved = localStorage.getItem('hydration-quick-amounts');
    if (saved) {
      const parsed = JSON.parse(saved);
      if (Array.isArray(parsed) && parsed.length === 3) {
        return parsed;
      }
    }
  } catch (e) {
    // ignore
  }
  return DEFAULT_AMOUNTS_ML;
};

// Save quick amounts to localStorage
const saveQuickAmounts = (amounts: number[]) => {
  localStorage.setItem('hydration-quick-amounts', JSON.stringify(amounts));
};

export default function HydrationTracker({ userId, workoutId, compact = false }: HydrationTrackerProps) {
  const queryClient = useQueryClient();
  const [selectedDrink, setSelectedDrink] = useState<DrinkType>('water');
  const [showAmountPicker, setShowAmountPicker] = useState(false);
  const [justLogged, setJustLogged] = useState(false);
  const [lastLoggedAmount, setLastLoggedAmount] = useState<number | null>(null);
  const [showCustomInput, setShowCustomInput] = useState(false);
  const [customAmount, setCustomAmount] = useState('');
  const [quickAmounts, setQuickAmounts] = useState<number[]>(DEFAULT_AMOUNTS_ML);

  // Load quick amounts on mount
  useEffect(() => {
    setQuickAmounts(loadQuickAmounts());
  }, []);

  // Get unit preference from global store (synced with Settings)
  const { notificationSettings, setNotificationSettings } = useAppStore();
  const unit: Unit = notificationSettings.hydrationUnit || 'oz';
  const goalFromSettings = notificationSettings.hydrationDailyGoalMl || 2500;

  // Toggle unit preference (updates global store)
  const toggleUnit = () => {
    const newUnit = unit === 'oz' ? 'ml' : 'oz';
    setNotificationSettings({ hydrationUnit: newUnit });
  };

  // Fetch daily hydration summary
  const { data: hydrationData } = useQuery<DailyHydrationSummary>({
    queryKey: ['hydration', 'daily', userId],
    queryFn: () => getDailyHydration(userId),
    enabled: !!userId,
    staleTime: 1000 * 60,
    retry: false,
  });

  // Log hydration mutation
  const logMutation = useMutation({
    mutationFn: ({ drinkType, amountMl }: { drinkType: string; amountMl: number }) =>
      quickLogHydration(userId, drinkType, amountMl, workoutId),
    onSuccess: (_, variables) => {
      queryClient.invalidateQueries({ queryKey: ['hydration', 'daily', userId] });
      setJustLogged(true);
      setLastLoggedAmount(variables.amountMl);
      setTimeout(() => {
        setJustLogged(false);
        setLastLoggedAmount(null);
      }, 2000);
      setShowAmountPicker(false);
      setShowCustomInput(false);
      setCustomAmount('');
    },
  });

  const handleQuickLog = (amountMl: number) => {
    logMutation.mutate({ drinkType: selectedDrink, amountMl });

    // Update quick amounts - add this amount if not already in list
    if (!quickAmounts.includes(amountMl)) {
      // Replace the least recently used (last in array) with the new amount
      const newAmounts = [amountMl, quickAmounts[0], quickAmounts[1]];
      setQuickAmounts(newAmounts);
      saveQuickAmounts(newAmounts);
    }
  };

  const handleCustomSubmit = () => {
    const value = parseFloat(customAmount);
    if (isNaN(value) || value <= 0) return;

    // Convert to ml if user entered oz
    const amountMl = unit === 'oz' ? ozToMl(value) : value;
    handleQuickLog(amountMl);
  };

  const totalMl = hydrationData?.total_ml ?? 0;
  // Use goal from settings, fallback to API response, then default
  const goalMl = goalFromSettings || hydrationData?.goal_ml || 2500;
  const percentage = Math.min(100, Math.round((totalMl / goalMl) * 100));

  const displayTotal = unit === 'oz' ? `${mlToOz(totalMl)}oz` : `${totalMl}ml`;
  const displayGoal = unit === 'oz' ? `${mlToOz(goalMl)}oz` : `${goalMl}ml`;
  const lastLoggedLabel = lastLoggedAmount ? getAmountLabel(lastLoggedAmount, unit) : null;

  if (compact) {
    return (
      <div className="relative">
        <motion.button
          onClick={() => setShowAmountPicker(!showAmountPicker)}
          className={`flex items-center gap-2 px-3 py-2 rounded-xl transition-all ${
            justLogged
              ? 'bg-emerald-500/20 border border-emerald-500/40'
              : 'bg-white/10 hover:bg-white/15 border border-white/10'
          }`}
          whileTap={{ scale: 0.95 }}
        >
          <span className="text-lg">💧</span>
          <div className="text-left">
            <div className="text-xs text-text-muted">Hydration</div>
            <div className="text-sm font-semibold text-text">{displayTotal}</div>
          </div>
          <div className="w-12 h-1.5 bg-white/10 rounded-full overflow-hidden">
            <motion.div
              className="h-full bg-gradient-to-r from-blue-500 to-cyan-400"
              initial={{ width: 0 }}
              animate={{ width: `${percentage}%` }}
              transition={{ duration: 0.5 }}
            />
          </div>
        </motion.button>

        <AnimatePresence>
          {showAmountPicker && (
            <motion.div
              initial={{ opacity: 0, y: -10, scale: 0.95 }}
              animate={{ opacity: 1, y: 0, scale: 1 }}
              exit={{ opacity: 0, y: -10, scale: 0.95 }}
              className="absolute top-full mt-2 right-0 z-50 bg-surface border border-white/10 rounded-xl p-3 shadow-xl min-w-64"
            >
              {/* Drink type + Unit toggle row */}
              <div className="flex items-center justify-between mb-2">
                <div className="flex gap-1">
                  {DRINK_OPTIONS.map((opt) => (
                    <button
                      key={opt.type}
                      onClick={() => setSelectedDrink(opt.type)}
                      className={`p-1.5 rounded-lg transition-all ${
                        selectedDrink === opt.type
                          ? `bg-gradient-to-r ${opt.color}`
                          : 'bg-white/5 hover:bg-white/10'
                      }`}
                    >
                      <span className="text-sm">{opt.icon}</span>
                    </button>
                  ))}
                </div>
                <button
                  onClick={toggleUnit}
                  className="text-xs px-2 py-1 rounded bg-white/10 hover:bg-white/15 text-text-muted"
                >
                  {unit.toUpperCase()}
                </button>
              </div>

              {/* Quick amount buttons */}
              <div className="flex gap-2 mb-2">
                {quickAmounts.map((ml) => (
                  <motion.button
                    key={ml}
                    onClick={() => handleQuickLog(ml)}
                    disabled={logMutation.isPending}
                    className="flex-1 py-2 px-2 bg-blue-500/20 hover:bg-blue-500/30 rounded-lg text-center transition-colors disabled:opacity-50"
                    whileTap={{ scale: 0.95 }}
                  >
                    <div className="text-sm font-medium text-text">{getAmountLabel(ml, unit)}</div>
                  </motion.button>
                ))}
              </div>

              {/* Custom input toggle / input field */}
              {showCustomInput ? (
                <div className="flex gap-2">
                  <input
                    type="number"
                    value={customAmount}
                    onChange={(e) => setCustomAmount(e.target.value)}
                    placeholder={unit === 'oz' ? 'oz' : 'ml'}
                    className="flex-1 px-3 py-2 bg-white/10 border border-white/20 rounded-lg text-text text-sm placeholder:text-text-muted focus:outline-none focus:border-blue-500"
                    autoFocus
                    onKeyDown={(e) => {
                      if (e.key === 'Enter') handleCustomSubmit();
                      if (e.key === 'Escape') {
                        setShowCustomInput(false);
                        setCustomAmount('');
                      }
                    }}
                  />
                  <button
                    onClick={handleCustomSubmit}
                    disabled={logMutation.isPending || !customAmount}
                    className="px-3 py-2 bg-blue-500 hover:bg-blue-600 rounded-lg text-white text-sm font-medium disabled:opacity-50 transition-colors"
                  >
                    Add
                  </button>
                </div>
              ) : (
                <button
                  onClick={() => setShowCustomInput(true)}
                  className="w-full py-1.5 text-xs text-text-muted hover:text-text transition-colors"
                >
                  + Custom amount
                </button>
              )}
            </motion.div>
          )}
        </AnimatePresence>
      </div>
    );
  }

  // Full version - consolidated layout
  return (
    <div className="bg-white/5 rounded-xl p-3 border border-white/10">
      {/* Header row: icon + progress + unit toggle */}
      <div className="flex items-center gap-3 mb-2">
        <span className="text-lg">💧</span>
        <div className="flex-1">
          <div className="flex items-center justify-between text-xs mb-0.5">
            <span className="text-text font-medium">{displayTotal}</span>
            <span className="text-text-muted">{displayGoal}</span>
          </div>
          <div className="h-1.5 bg-white/10 rounded-full overflow-hidden">
            <motion.div
              className="h-full bg-gradient-to-r from-blue-500 to-cyan-400"
              initial={{ width: 0 }}
              animate={{ width: `${percentage}%` }}
              transition={{ duration: 0.5 }}
            />
          </div>
        </div>
        <button
          onClick={toggleUnit}
          className="text-xs px-2 py-1 rounded bg-white/10 hover:bg-white/15 text-text-muted transition-colors"
        >
          {unit.toUpperCase()}
        </button>
        {justLogged && lastLoggedLabel && (
          <motion.span
            initial={{ opacity: 0, scale: 0.8 }}
            animate={{ opacity: 1, scale: 1 }}
            exit={{ opacity: 0 }}
            className="text-emerald-400 text-xs font-medium"
          >
            +{lastLoggedLabel}
          </motion.span>
        )}
      </div>

      {/* Drink type + Amount buttons in one row */}
      <div className="flex items-center gap-2">
        {/* Drink type selector */}
        <div className="flex gap-1">
          {DRINK_OPTIONS.map((opt) => (
            <motion.button
              key={opt.type}
              onClick={() => setSelectedDrink(opt.type)}
              className={`p-1.5 rounded-lg transition-all ${
                selectedDrink === opt.type
                  ? `bg-gradient-to-r ${opt.color}`
                  : 'bg-white/5 hover:bg-white/10'
              }`}
              whileTap={{ scale: 0.95 }}
            >
              <span className="text-sm">{opt.icon}</span>
            </motion.button>
          ))}
        </div>

        {/* Divider */}
        <div className="w-px h-6 bg-white/10" />

        {/* Amount buttons */}
        <div className="flex gap-1.5 flex-1">
          {quickAmounts.map((ml) => (
            <motion.button
              key={ml}
              onClick={() => handleQuickLog(ml)}
              disabled={logMutation.isPending}
              className="flex-1 py-1.5 px-2 bg-white/5 hover:bg-white/10 rounded-lg text-center transition-colors disabled:opacity-50"
              whileTap={{ scale: 0.95 }}
            >
              <span className="text-xs font-medium text-text">{getAmountLabel(ml, unit)}</span>
            </motion.button>
          ))}
        </div>

        {/* Custom input button */}
        <button
          onClick={() => setShowCustomInput(!showCustomInput)}
          className={`p-1.5 rounded-lg transition-colors ${
            showCustomInput ? 'bg-blue-500/30 text-blue-400' : 'bg-white/5 hover:bg-white/10 text-text-muted'
          }`}
          title="Custom amount"
        >
          <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 6v6m0 0v6m0-6h6m-6 0H6" />
          </svg>
        </button>

        {logMutation.isPending && (
          <div className="w-4 h-4 border-2 border-primary border-t-transparent rounded-full animate-spin" />
        )}
      </div>

      {/* Custom input row */}
      <AnimatePresence>
        {showCustomInput && (
          <motion.div
            initial={{ opacity: 0, height: 0 }}
            animate={{ opacity: 1, height: 'auto' }}
            exit={{ opacity: 0, height: 0 }}
            className="overflow-hidden"
          >
            <div className="flex gap-2 mt-2 pt-2 border-t border-white/10">
              <input
                type="number"
                value={customAmount}
                onChange={(e) => setCustomAmount(e.target.value)}
                placeholder={`Enter ${unit === 'oz' ? 'oz' : 'ml'}`}
                className="flex-1 px-3 py-2 bg-white/10 border border-white/20 rounded-lg text-text text-sm placeholder:text-text-muted focus:outline-none focus:border-blue-500"
                autoFocus
                onKeyDown={(e) => {
                  if (e.key === 'Enter') handleCustomSubmit();
                  if (e.key === 'Escape') {
                    setShowCustomInput(false);
                    setCustomAmount('');
                  }
                }}
              />
              <button
                onClick={handleCustomSubmit}
                disabled={logMutation.isPending || !customAmount}
                className="px-4 py-2 bg-blue-500 hover:bg-blue-600 rounded-lg text-white text-sm font-medium disabled:opacity-50 transition-colors"
              >
                Add
              </button>
            </div>
          </motion.div>
        )}
      </AnimatePresence>
    </div>
  );
}
