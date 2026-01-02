/**
 * StatsCard - Dashboard statistics card with glassmorphism style
 */
import type { ReactNode } from 'react';

interface StatsCardProps {
  title: string;
  value: string | number;
  subtitle?: string;
  icon: ReactNode;
  trend?: {
    value: number;
    direction: 'up' | 'down';
    label: string;
  };
  variant?: 'default' | 'primary' | 'success' | 'warning' | 'danger';
}

const variantStyles = {
  default: {
    iconBg: 'bg-white/10',
    iconText: 'text-text-secondary',
  },
  primary: {
    iconBg: 'bg-primary/20',
    iconText: 'text-primary',
  },
  success: {
    iconBg: 'bg-green-500/20',
    iconText: 'text-green-400',
  },
  warning: {
    iconBg: 'bg-orange-500/20',
    iconText: 'text-orange-400',
  },
  danger: {
    iconBg: 'bg-red-500/20',
    iconText: 'text-red-400',
  },
};

export default function StatsCard({
  title,
  value,
  subtitle,
  icon,
  trend,
  variant = 'default',
}: StatsCardProps) {
  const styles = variantStyles[variant];

  return (
    <div className="glass-card p-6 rounded-2xl">
      <div className="flex items-start justify-between">
        <div className="flex-1">
          <p className="text-sm text-text-secondary mb-1">{title}</p>
          <p className="text-3xl font-bold text-text">{value}</p>
          {subtitle && (
            <p className="text-sm text-text-muted mt-1">{subtitle}</p>
          )}
          {trend && (
            <div className="flex items-center gap-1 mt-2">
              <span
                className={`text-sm font-medium ${
                  trend.direction === 'up' ? 'text-green-400' : 'text-red-400'
                }`}
              >
                {trend.direction === 'up' ? '+' : '-'}
                {Math.abs(trend.value)}%
              </span>
              <span className="text-xs text-text-muted">{trend.label}</span>
            </div>
          )}
        </div>
        <div className={`p-3 rounded-xl ${styles.iconBg}`}>
          <div className={styles.iconText}>{icon}</div>
        </div>
      </div>
    </div>
  );
}
