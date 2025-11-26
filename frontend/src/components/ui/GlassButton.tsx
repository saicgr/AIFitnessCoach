import type { ReactNode, ButtonHTMLAttributes } from 'react';

interface GlassButtonProps extends ButtonHTMLAttributes<HTMLButtonElement> {
  children: ReactNode;
  variant?: 'primary' | 'secondary' | 'ghost' | 'danger';
  size?: 'sm' | 'md' | 'lg';
  fullWidth?: boolean;
  loading?: boolean;
  icon?: ReactNode;
  iconPosition?: 'left' | 'right';
}

export default function GlassButton({
  children,
  variant = 'primary',
  size = 'md',
  fullWidth = false,
  loading = false,
  icon,
  iconPosition = 'left',
  className = '',
  disabled,
  ...props
}: GlassButtonProps) {
  const baseClasses = `
    relative inline-flex items-center justify-center gap-2
    font-semibold rounded-xl
    transition-all duration-200 ease-out
    focus:outline-none focus-visible:ring-2 focus-visible:ring-primary focus-visible:ring-offset-2 focus-visible:ring-offset-background
    disabled:opacity-50 disabled:cursor-not-allowed disabled:transform-none
  `;

  const sizeClasses = {
    sm: 'px-4 py-2 text-sm',
    md: 'px-6 py-3 text-base',
    lg: 'px-8 py-4 text-lg',
  };

  const variantClasses = {
    primary: `
      bg-gradient-to-r from-primary to-primary-dark
      text-white
      shadow-[0_0_20px_rgba(6,182,212,0.4),0_4px_12px_rgba(0,0,0,0.3)]
      hover:shadow-[0_0_30px_rgba(6,182,212,0.5),0_8px_20px_rgba(0,0,0,0.4)]
      hover:-translate-y-0.5
      active:scale-[0.98]
    `,
    secondary: `
      bg-white/5
      text-text
      border border-white/15
      hover:bg-white/10 hover:border-primary/50
      active:scale-[0.98]
    `,
    ghost: `
      bg-transparent
      text-text-secondary
      hover:bg-white/5 hover:text-text
      active:scale-[0.98]
    `,
    danger: `
      bg-gradient-to-r from-coral to-coral/80
      text-white
      shadow-[0_0_20px_rgba(244,63,94,0.4),0_4px_12px_rgba(0,0,0,0.3)]
      hover:shadow-[0_0_30px_rgba(244,63,94,0.5),0_8px_20px_rgba(0,0,0,0.4)]
      hover:-translate-y-0.5
      active:scale-[0.98]
    `,
  };

  const widthClass = fullWidth ? 'w-full' : '';

  return (
    <button
      className={`${baseClasses} ${sizeClasses[size]} ${variantClasses[variant]} ${widthClass} ${className}`}
      disabled={disabled || loading}
      {...props}
    >
      {loading && (
        <svg
          className="animate-spin h-5 w-5"
          xmlns="http://www.w3.org/2000/svg"
          fill="none"
          viewBox="0 0 24 24"
        >
          <circle
            className="opacity-25"
            cx="12"
            cy="12"
            r="10"
            stroke="currentColor"
            strokeWidth="4"
          />
          <path
            className="opacity-75"
            fill="currentColor"
            d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"
          />
        </svg>
      )}
      {!loading && icon && iconPosition === 'left' && icon}
      {children}
      {!loading && icon && iconPosition === 'right' && icon}
    </button>
  );
}
