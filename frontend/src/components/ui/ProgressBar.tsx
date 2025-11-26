interface ProgressBarProps {
  current: number;
  total: number;
  showLabels?: boolean;
  variant?: 'default' | 'glow';
  animated?: boolean;
}

export default function ProgressBar({
  current,
  total,
  showLabels = false,
  variant = 'default',
  animated = true,
}: ProgressBarProps) {
  const percentage = Math.min(100, Math.max(0, (current / total) * 100));

  return (
    <div className="space-y-2">
      {showLabels && (
        <div className="flex justify-between text-sm">
          <span className="text-text-secondary">Progress</span>
          <span className="text-text font-medium">{Math.round(percentage)}%</span>
        </div>
      )}
      <div className="relative h-2 bg-white/10 rounded-full overflow-hidden">
        <div
          className={`
            h-full rounded-full
            bg-gradient-to-r from-primary to-primary-light
            ${animated ? 'transition-all duration-500 ease-out' : ''}
            ${variant === 'glow' ? 'shadow-[0_0_10px_rgba(6,182,212,0.5)]' : ''}
          `}
          style={{ width: `${percentage}%` }}
        />
        {/* Shimmer effect */}
        {animated && percentage < 100 && (
          <div
            className="absolute inset-0 bg-gradient-to-r from-transparent via-white/20 to-transparent animate-[shimmer_2s_infinite]"
            style={{ width: `${percentage}%` }}
          />
        )}
      </div>
    </div>
  );
}
