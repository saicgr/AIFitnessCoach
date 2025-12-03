import { useQuery } from '@tanstack/react-query';
import { useAppStore } from '../store';
import DashboardLayout from '../components/layout/DashboardLayout';
import {
  getAchievementsSummary,
  getAchievementTypes,
  getUserAchievements,
  type AchievementType,
  type UserAchievement,
  type AchievementsSummary,
} from '../api/client';

const tierColors = {
  bronze: 'from-amber-700 to-amber-500',
  silver: 'from-gray-400 to-gray-300',
  gold: 'from-yellow-500 to-yellow-300',
  platinum: 'from-purple-500 to-purple-300',
};

const tierBgColors = {
  bronze: 'bg-amber-500/10 border-amber-500/30',
  silver: 'bg-gray-400/10 border-gray-400/30',
  gold: 'bg-yellow-500/10 border-yellow-500/30',
  platinum: 'bg-purple-500/10 border-purple-500/30',
};

const categoryLabels: Record<string, string> = {
  strength: 'Strength',
  consistency: 'Consistency',
  weight: 'Weight',
  cardio: 'Cardio',
  habit: 'Habits',
};

function AchievementBadge({
  achievement,
  earned,
  earnedAt,
}: {
  achievement: AchievementType;
  earned: boolean;
  earnedAt?: string;
}) {
  return (
    <div
      className={`relative p-4 rounded-2xl border transition-all ${
        earned
          ? `${tierBgColors[achievement.tier]} hover:scale-105`
          : 'bg-white/5 border-white/10 opacity-50'
      }`}
    >
      {/* Icon */}
      <div className="text-4xl text-center mb-2">{achievement.icon}</div>

      {/* Name */}
      <h3 className="text-sm font-medium text-text text-center truncate">{achievement.name}</h3>

      {/* Description */}
      <p className="text-xs text-text-muted text-center mt-1 line-clamp-2">
        {achievement.description}
      </p>

      {/* Points badge */}
      <div
        className={`absolute -top-2 -right-2 px-2 py-0.5 rounded-full text-xs font-bold bg-gradient-to-r ${
          tierColors[achievement.tier]
        } text-white`}
      >
        +{achievement.points}
      </div>

      {/* Earned date */}
      {earned && earnedAt && (
        <p className="text-xs text-primary text-center mt-2">
          {new Date(earnedAt).toLocaleDateString()}
        </p>
      )}

      {/* Lock icon for unearned */}
      {!earned && (
        <div className="absolute inset-0 flex items-center justify-center">
          <div className="bg-black/40 rounded-full p-2">
            <svg className="w-6 h-6 text-text-muted" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path
                strokeLinecap="round"
                strokeLinejoin="round"
                strokeWidth={2}
                d="M12 15v2m-6 4h12a2 2 0 002-2v-6a2 2 0 00-2-2H6a2 2 0 00-2 2v6a2 2 0 002 2zm10-10V7a4 4 0 00-8 0v4h8z"
              />
            </svg>
          </div>
        </div>
      )}
    </div>
  );
}

function StreakCard({
  type,
  current,
  longest,
  icon,
}: {
  type: string;
  current: number;
  longest: number;
  icon: string;
}) {
  const typeLabels: Record<string, string> = {
    workout: 'Workout Streak',
    hydration: 'Hydration Streak',
    protein: 'Protein Streak',
    sleep: 'Sleep Streak',
  };

  return (
    <div className="bg-white/5 rounded-2xl p-4 border border-white/10">
      <div className="flex items-center gap-3">
        <div className="text-3xl">{icon}</div>
        <div className="flex-1">
          <h3 className="text-sm font-medium text-text">{typeLabels[type] || type}</h3>
          <div className="flex items-baseline gap-2 mt-1">
            <span className="text-2xl font-bold text-primary">{current}</span>
            <span className="text-text-muted text-sm">days</span>
          </div>
        </div>
        <div className="text-right">
          <p className="text-xs text-text-muted">Best</p>
          <p className="text-lg font-semibold text-text">{longest}</p>
        </div>
      </div>
    </div>
  );
}

function PRCard({
  exerciseName,
  value,
  unit,
  improvement,
  achievedAt,
}: {
  exerciseName: string;
  value: number;
  unit: string;
  improvement?: number;
  achievedAt: string;
}) {
  return (
    <div className="bg-white/5 rounded-xl p-3 border border-white/10">
      <div className="flex items-center justify-between">
        <div className="flex-1 min-w-0">
          <h4 className="text-sm font-medium text-text truncate">{exerciseName}</h4>
          <p className="text-xs text-text-muted">
            {new Date(achievedAt).toLocaleDateString()}
          </p>
        </div>
        <div className="text-right">
          <div className="flex items-baseline gap-1">
            <span className="text-lg font-bold text-primary">{value}</span>
            <span className="text-text-muted text-sm">{unit}</span>
          </div>
          {improvement && (
            <p className="text-xs text-green-400">+{improvement.toFixed(1)}%</p>
          )}
        </div>
      </div>
    </div>
  );
}

export default function Achievements() {
  const { user } = useAppStore();
  const userId = user?.id ? String(user.id) : undefined;

  const { data: summary, isLoading: summaryLoading } = useQuery<AchievementsSummary>({
    queryKey: ['achievements-summary', userId],
    queryFn: () => getAchievementsSummary(userId!),
    enabled: !!userId,
  });

  const { data: allTypes } = useQuery<AchievementType[]>({
    queryKey: ['achievement-types'],
    queryFn: getAchievementTypes,
  });

  const { data: userAchievements } = useQuery<UserAchievement[]>({
    queryKey: ['user-achievements', userId],
    queryFn: () => getUserAchievements(userId!),
    enabled: !!userId,
  });

  // Map of earned achievement IDs to their earned date
  const earnedMap = new Map<string, string>();
  userAchievements?.forEach((ua) => {
    earnedMap.set(ua.achievement_id, ua.earned_at);
  });

  // Group achievements by category
  const achievementsByCategory = new Map<string, AchievementType[]>();
  allTypes?.forEach((at) => {
    const existing = achievementsByCategory.get(at.category) || [];
    existing.push(at);
    achievementsByCategory.set(at.category, existing);
  });

  const streakIcons: Record<string, string> = {
    workout: '🔥',
    hydration: '💧',
    protein: '🥩',
    sleep: '😴',
  };

  if (summaryLoading) {
    return (
      <DashboardLayout>
        <div className="flex items-center justify-center min-h-[60vh]">
          <div className="w-8 h-8 border-2 border-primary border-t-transparent rounded-full animate-spin" />
        </div>
      </DashboardLayout>
    );
  }

  return (
    <DashboardLayout>
      <div className="space-y-6 pb-6">
        {/* Header with Points */}
        <div className="bg-gradient-to-br from-primary/20 to-purple-500/20 rounded-2xl p-6 border border-primary/30">
          <div className="flex items-center justify-between">
            <div>
              <h1 className="text-2xl font-bold text-text">Achievements</h1>
              <p className="text-text-muted mt-1">Track your milestones and progress</p>
            </div>
            <div className="text-right">
              <div className="text-4xl font-bold text-primary">{summary?.total_points || 0}</div>
              <p className="text-sm text-text-muted">Total Points</p>
            </div>
          </div>

          {/* Quick stats */}
          <div className="grid grid-cols-3 gap-4 mt-4">
            <div className="bg-white/5 rounded-xl p-3 text-center">
              <div className="text-2xl font-bold text-text">{summary?.total_achievements || 0}</div>
              <p className="text-xs text-text-muted">Achievements</p>
            </div>
            <div className="bg-white/5 rounded-xl p-3 text-center">
              <div className="text-2xl font-bold text-text">
                {summary?.current_streaks?.find((s) => s.streak_type === 'workout')?.current_streak || 0}
              </div>
              <p className="text-xs text-text-muted">Day Streak</p>
            </div>
            <div className="bg-white/5 rounded-xl p-3 text-center">
              <div className="text-2xl font-bold text-text">{summary?.personal_records?.length || 0}</div>
              <p className="text-xs text-text-muted">PRs Set</p>
            </div>
          </div>
        </div>

        {/* Current Streaks */}
        {summary?.current_streaks && summary.current_streaks.length > 0 && (
          <section>
            <h2 className="text-lg font-semibold text-text mb-3">Current Streaks</h2>
            <div className="grid gap-3">
              {summary.current_streaks.map((streak) => (
                <StreakCard
                  key={streak.id}
                  type={streak.streak_type}
                  current={streak.current_streak}
                  longest={streak.longest_streak}
                  icon={streakIcons[streak.streak_type] || '🔥'}
                />
              ))}
            </div>
          </section>
        )}

        {/* Recent PRs */}
        {summary?.personal_records && summary.personal_records.length > 0 && (
          <section>
            <h2 className="text-lg font-semibold text-text mb-3">Personal Records</h2>
            <div className="grid gap-2">
              {summary.personal_records.slice(0, 5).map((pr) => (
                <PRCard
                  key={pr.id}
                  exerciseName={pr.exercise_name}
                  value={pr.record_value}
                  unit={pr.record_unit}
                  improvement={pr.improvement_percentage}
                  achievedAt={pr.achieved_at}
                />
              ))}
            </div>
          </section>
        )}

        {/* Achievements by Category */}
        {Array.from(achievementsByCategory.entries()).map(([category, achievements]) => (
          <section key={category}>
            <div className="flex items-center justify-between mb-3">
              <h2 className="text-lg font-semibold text-text">
                {categoryLabels[category] || category}
              </h2>
              <span className="text-sm text-text-muted">
                {achievements.filter((a) => earnedMap.has(a.id)).length} / {achievements.length}
              </span>
            </div>
            <div className="grid grid-cols-2 sm:grid-cols-3 lg:grid-cols-4 gap-3">
              {achievements.map((achievement) => (
                <AchievementBadge
                  key={achievement.id}
                  achievement={achievement}
                  earned={earnedMap.has(achievement.id)}
                  earnedAt={earnedMap.get(achievement.id)}
                />
              ))}
            </div>
          </section>
        ))}

        {/* Empty state */}
        {(!allTypes || allTypes.length === 0) && (
          <div className="text-center py-12">
            <div className="text-6xl mb-4">🏆</div>
            <h3 className="text-lg font-medium text-text">No achievements yet</h3>
            <p className="text-text-muted mt-2">
              Complete workouts and hit milestones to earn achievements!
            </p>
          </div>
        )}
      </div>
    </DashboardLayout>
  );
}
