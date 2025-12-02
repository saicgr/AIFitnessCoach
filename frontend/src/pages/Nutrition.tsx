import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { useAppStore } from '../store';
import {
  getDailyNutritionSummary,
  getWeeklyNutritionSummary,
  getNutritionTargets,
  deleteFoodLog,
  type FoodLogResponse,
} from '../api/client';
import { createLogger } from '../utils/logger';
import { GlassCard, GlassButton, ProgressBar } from '../components/ui';
import { DashboardLayout } from '../components/layout';

const log = createLogger('nutrition');

// Icons
const Icons = {
  Back: () => (
    <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 19l-7-7 7-7" />
    </svg>
  ),
  Fire: () => (
    <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M17.657 18.657A8 8 0 016.343 7.343S7 9 9 10c0-2 .5-5 2.986-7C14 5 16.09 5.777 17.656 7.343A7.975 7.975 0 0120 13a7.975 7.975 0 01-2.343 5.657z" />
    </svg>
  ),
  Protein: () => (
    <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z" />
    </svg>
  ),
  Carbs: () => (
    <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M20 7l-8-4-8 4m16 0l-8 4m8-4v10l-8 4m0-10L4 7m8 4v10M4 7v10l8 4" />
    </svg>
  ),
  Fat: () => (
    <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4.318 6.318a4.5 4.5 0 000 6.364L12 20.364l7.682-7.682a4.5 4.5 0 00-6.364-6.364L12 7.636l-1.318-1.318a4.5 4.5 0 00-6.364 0z" />
    </svg>
  ),
  Camera: () => (
    <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M3 9a2 2 0 012-2h.93a2 2 0 001.664-.89l.812-1.22A2 2 0 0110.07 4h3.86a2 2 0 011.664.89l.812 1.22A2 2 0 0018.07 7H19a2 2 0 012 2v9a2 2 0 01-2 2H5a2 2 0 01-2-2V9z" />
      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 13a3 3 0 11-6 0 3 3 0 016 0z" />
    </svg>
  ),
  Trash: () => (
    <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" />
    </svg>
  ),
  ChevronLeft: () => (
    <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 19l-7-7 7-7" />
    </svg>
  ),
  ChevronRight: () => (
    <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 5l7 7-7 7" />
    </svg>
  ),
};

// Stat Card Component
function MacroCard({
  icon,
  value,
  target,
  label,
  unit,
  color,
}: {
  icon: React.ReactNode;
  value: number;
  target?: number;
  label: string;
  unit: string;
  color: 'primary' | 'secondary' | 'accent' | 'orange';
}) {
  const colorClasses = {
    primary: 'bg-primary/20 text-primary border-primary/30',
    secondary: 'bg-secondary/20 text-secondary border-secondary/30',
    accent: 'bg-accent/20 text-accent border-accent/30',
    orange: 'bg-orange/20 text-orange border-orange/30',
  };

  const progressPercent = target ? Math.min((value / target) * 100, 100) : 0;

  return (
    <GlassCard className="p-4" hoverable>
      <div className="flex items-center gap-3 mb-3">
        <div className={`w-10 h-10 rounded-xl flex items-center justify-center ${colorClasses[color]}`}>
          {icon}
        </div>
        <div className="flex-1">
          <div className="text-xs text-text-secondary">{label}</div>
          <div className="text-xl font-bold text-text">
            {Math.round(value)}<span className="text-sm text-text-muted ml-1">{unit}</span>
          </div>
        </div>
      </div>
      {target && (
        <div>
          <div className="flex justify-between text-xs text-text-muted mb-1">
            <span>{Math.round(progressPercent)}%</span>
            <span>Goal: {target}{unit}</span>
          </div>
          <ProgressBar current={progressPercent} total={100} />
        </div>
      )}
    </GlassCard>
  );
}

// Meal Card Component
function MealCard({ meal, onDelete }: { meal: FoodLogResponse; onDelete: () => void }) {
  const mealTypeColors: Record<string, string> = {
    breakfast: 'bg-yellow-500/20 text-yellow-400',
    lunch: 'bg-green-500/20 text-green-400',
    dinner: 'bg-blue-500/20 text-blue-400',
    snack: 'bg-purple-500/20 text-purple-400',
  };

  const mealTypeIcons: Record<string, string> = {
    breakfast: '🌅',
    lunch: '☀️',
    dinner: '🌙',
    snack: '🍪',
  };

  const time = new Date(meal.logged_at).toLocaleTimeString('en-US', {
    hour: 'numeric',
    minute: '2-digit',
    hour12: true,
  });

  return (
    <GlassCard className="p-4" hoverable>
      <div className="flex items-start justify-between">
        <div className="flex items-center gap-3">
          <div className={`w-10 h-10 rounded-xl flex items-center justify-center ${mealTypeColors[meal.meal_type] || 'bg-gray-500/20 text-gray-400'}`}>
            <span className="text-lg">{mealTypeIcons[meal.meal_type] || '🍽️'}</span>
          </div>
          <div>
            <div className="flex items-center gap-2">
              <span className="font-semibold text-text capitalize">{meal.meal_type}</span>
              <span className="text-xs text-text-muted">{time}</span>
            </div>
            <div className="text-sm text-text-secondary">
              {meal.food_items.map(item => item.name).join(', ')}
            </div>
          </div>
        </div>
        <button
          onClick={onDelete}
          className="p-2 text-text-muted hover:text-red-400 hover:bg-red-400/10 rounded-lg transition-colors"
          title="Delete meal"
        >
          <Icons.Trash />
        </button>
      </div>

      <div className="mt-3 grid grid-cols-4 gap-2 text-center">
        <div className="bg-white/5 rounded-lg p-2">
          <div className="text-lg font-bold text-orange">{meal.total_calories}</div>
          <div className="text-xs text-text-muted">kcal</div>
        </div>
        <div className="bg-white/5 rounded-lg p-2">
          <div className="text-lg font-bold text-primary">{Math.round(meal.protein_g)}g</div>
          <div className="text-xs text-text-muted">Protein</div>
        </div>
        <div className="bg-white/5 rounded-lg p-2">
          <div className="text-lg font-bold text-accent">{Math.round(meal.carbs_g)}g</div>
          <div className="text-xs text-text-muted">Carbs</div>
        </div>
        <div className="bg-white/5 rounded-lg p-2">
          <div className="text-lg font-bold text-secondary">{Math.round(meal.fat_g)}g</div>
          <div className="text-xs text-text-muted">Fat</div>
        </div>
      </div>

      {meal.health_score && (
        <div className="mt-3 flex items-center gap-2">
          <span className="text-xs text-text-muted">Health Score:</span>
          <div className="flex gap-0.5">
            {[...Array(10)].map((_, i) => (
              <div
                key={i}
                className={`w-2 h-2 rounded-full ${
                  i < meal.health_score! ? 'bg-green-400' : 'bg-white/10'
                }`}
              />
            ))}
          </div>
          <span className="text-xs font-semibold text-green-400">{meal.health_score}/10</span>
        </div>
      )}

      {meal.ai_feedback && (
        <div className="mt-3 p-2 bg-white/5 rounded-lg">
          <p className="text-xs text-text-secondary">{meal.ai_feedback}</p>
        </div>
      )}
    </GlassCard>
  );
}

export default function Nutrition() {
  const navigate = useNavigate();
  const queryClient = useQueryClient();
  const { user } = useAppStore();
  const [selectedDate, setSelectedDate] = useState(new Date().toISOString().split('T')[0]);

  // Fetch daily summary
  const { data: dailySummary, isLoading: loadingDaily } = useQuery({
    queryKey: ['nutrition', 'daily', user?.id, selectedDate],
    queryFn: () => getDailyNutritionSummary(String(user?.id), selectedDate),
    enabled: !!user?.id,
  });

  // Fetch weekly summary
  const { data: weeklySummary } = useQuery({
    queryKey: ['nutrition', 'weekly', user?.id],
    queryFn: () => getWeeklyNutritionSummary(String(user?.id)),
    enabled: !!user?.id,
  });

  // Fetch nutrition targets
  const { data: targets } = useQuery({
    queryKey: ['nutrition', 'targets', user?.id],
    queryFn: () => getNutritionTargets(String(user?.id)),
    enabled: !!user?.id,
  });

  // Delete mutation
  const deleteMutation = useMutation({
    mutationFn: deleteFoodLog,
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['nutrition'] });
      log.info('Food log deleted');
    },
    onError: (error) => {
      log.error('Failed to delete food log:', error);
    },
  });

  const handleDeleteMeal = (logId: string) => {
    if (window.confirm('Delete this meal log?')) {
      deleteMutation.mutate(logId);
    }
  };

  const navigateDate = (direction: 'prev' | 'next') => {
    const date = new Date(selectedDate);
    date.setDate(date.getDate() + (direction === 'next' ? 1 : -1));
    setSelectedDate(date.toISOString().split('T')[0]);
  };

  const isToday = selectedDate === new Date().toISOString().split('T')[0];

  const formatDate = (dateStr: string) => {
    const date = new Date(dateStr);
    const today = new Date();
    const yesterday = new Date(today);
    yesterday.setDate(yesterday.getDate() - 1);

    if (dateStr === today.toISOString().split('T')[0]) return 'Today';
    if (dateStr === yesterday.toISOString().split('T')[0]) return 'Yesterday';
    return date.toLocaleDateString('en-US', { weekday: 'short', month: 'short', day: 'numeric' });
  };

  return (
    <DashboardLayout>
      <div className="space-y-6">
        {/* Header */}
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-4">
            <button
              onClick={() => navigate('/')}
              className="p-2 hover:bg-white/10 rounded-xl transition-colors text-text-secondary hover:text-text"
            >
              <Icons.Back />
            </button>
            <div>
              <h1 className="text-2xl font-bold text-text">Nutrition</h1>
              <p className="text-sm text-text-secondary">Track your food and macros</p>
            </div>
          </div>
          <GlassButton
            onClick={() => navigate('/chat')}
            icon={<Icons.Camera />}
          >
            Log Food
          </GlassButton>
        </div>

        {/* Date Navigator */}
        <GlassCard className="p-3">
          <div className="flex items-center justify-between">
            <button
              onClick={() => navigateDate('prev')}
              className="p-2 hover:bg-white/10 rounded-lg transition-colors text-text-secondary hover:text-text"
            >
              <Icons.ChevronLeft />
            </button>
            <div className="text-center">
              <div className="font-semibold text-text">{formatDate(selectedDate)}</div>
              <div className="text-xs text-text-muted">{selectedDate}</div>
            </div>
            <button
              onClick={() => navigateDate('next')}
              disabled={isToday}
              className={`p-2 rounded-lg transition-colors ${
                isToday
                  ? 'text-text-muted cursor-not-allowed'
                  : 'hover:bg-white/10 text-text-secondary hover:text-text'
              }`}
            >
              <Icons.ChevronRight />
            </button>
          </div>
        </GlassCard>

        {/* Daily Macros */}
        <div className="grid grid-cols-2 gap-3">
          <MacroCard
            icon={<Icons.Fire />}
            value={dailySummary?.total_calories || 0}
            target={targets?.daily_calorie_target}
            label="Calories"
            unit="kcal"
            color="orange"
          />
          <MacroCard
            icon={<Icons.Protein />}
            value={dailySummary?.total_protein_g || 0}
            target={targets?.daily_protein_target_g}
            label="Protein"
            unit="g"
            color="primary"
          />
          <MacroCard
            icon={<Icons.Carbs />}
            value={dailySummary?.total_carbs_g || 0}
            target={targets?.daily_carbs_target_g}
            label="Carbs"
            unit="g"
            color="accent"
          />
          <MacroCard
            icon={<Icons.Fat />}
            value={dailySummary?.total_fat_g || 0}
            target={targets?.daily_fat_target_g}
            label="Fat"
            unit="g"
            color="secondary"
          />
        </div>

        {/* Weekly Overview */}
        {weeklySummary && (
          <GlassCard className="p-4">
            <h2 className="font-semibold text-text mb-4">Weekly Overview</h2>
            <div className="flex justify-between items-end h-24 gap-1">
              {weeklySummary.daily_summaries.map((day, idx) => {
                const maxCal = Math.max(...weeklySummary.daily_summaries.map(d => d.total_calories || 1));
                const height = day.total_calories ? (day.total_calories / maxCal) * 100 : 5;
                const isSelected = day.date === selectedDate;
                const dayLabel = new Date(day.date).toLocaleDateString('en-US', { weekday: 'short' });

                return (
                  <button
                    key={idx}
                    onClick={() => setSelectedDate(day.date)}
                    className={`flex-1 flex flex-col items-center gap-1 ${
                      isSelected ? 'opacity-100' : 'opacity-60 hover:opacity-80'
                    }`}
                  >
                    <div
                      className={`w-full rounded-t transition-all ${
                        isSelected ? 'bg-primary' : 'bg-white/20'
                      }`}
                      style={{ height: `${height}%`, minHeight: '4px' }}
                    />
                    <span className={`text-xs ${isSelected ? 'text-primary font-semibold' : 'text-text-muted'}`}>
                      {dayLabel}
                    </span>
                  </button>
                );
              })}
            </div>
            <div className="mt-4 flex justify-between text-sm text-text-muted">
              <span>Avg: {Math.round(weeklySummary.average_daily_calories)} kcal/day</span>
              <span>{weeklySummary.total_meals} meals this week</span>
            </div>
          </GlassCard>
        )}

        {/* Today's Meals */}
        <div>
          <h2 className="font-semibold text-text mb-3 flex items-center gap-2">
            <span>{formatDate(selectedDate)}'s Meals</span>
            {dailySummary?.meal_count ? (
              <span className="px-2 py-0.5 bg-primary/20 text-primary text-xs rounded-full">
                {dailySummary.meal_count} meals
              </span>
            ) : null}
          </h2>

          {loadingDaily ? (
            <GlassCard className="p-8 text-center">
              <div className="animate-spin w-8 h-8 border-2 border-primary border-t-transparent rounded-full mx-auto mb-3" />
              <p className="text-text-secondary">Loading meals...</p>
            </GlassCard>
          ) : dailySummary?.meals && dailySummary.meals.length > 0 ? (
            <div className="space-y-3">
              {dailySummary.meals.map((meal) => (
                <MealCard
                  key={meal.id}
                  meal={meal}
                  onDelete={() => handleDeleteMeal(meal.id)}
                />
              ))}
            </div>
          ) : (
            <GlassCard className="p-8 text-center">
              <div className="w-16 h-16 bg-primary/20 rounded-full flex items-center justify-center mx-auto mb-4">
                <Icons.Camera />
              </div>
              <h3 className="font-semibold text-text mb-2">No meals logged</h3>
              <p className="text-text-secondary text-sm mb-4">
                Take a photo of your food in the chat to log it
              </p>
              <GlassButton onClick={() => navigate('/chat')} icon={<Icons.Camera />}>
                Log Your First Meal
              </GlassButton>
            </GlassCard>
          )}
        </div>

        {/* Tips Card */}
        <GlassCard className="p-4 bg-gradient-to-r from-primary/10 to-secondary/10 border-primary/20">
          <h3 className="font-semibold text-text mb-2">Quick Tips</h3>
          <ul className="text-sm text-text-secondary space-y-1">
            <li>📸 Send food photos to AI Coach for instant analysis</li>
            <li>🎯 Set macro targets in Settings for personalized tracking</li>
            <li>📊 Check weekly trends to identify eating patterns</li>
          </ul>
        </GlassCard>
      </div>
    </DashboardLayout>
  );
}
