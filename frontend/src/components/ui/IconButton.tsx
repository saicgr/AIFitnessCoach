/**
 * IconButton - Premium reusable icon button component
 *
 * A consistent icon button used across the app for actions like
 * Start, Settings, Regenerate, Delete, Add, etc.
 */
import { forwardRef, ButtonHTMLAttributes } from 'react';

type IconButtonVariant = 'primary' | 'secondary' | 'ghost' | 'danger' | 'success' | 'accent';
type IconButtonSize = 'xs' | 'sm' | 'md' | 'lg';

interface IconButtonProps extends ButtonHTMLAttributes<HTMLButtonElement> {
  variant?: IconButtonVariant;
  size?: IconButtonSize;
  icon: React.ReactNode;
  label?: string;
  loading?: boolean;
  rounded?: boolean;
}

const variantStyles: Record<IconButtonVariant, string> = {
  primary: 'bg-primary/20 text-primary hover:bg-primary/30 hover:shadow-[0_0_20px_rgba(6,182,212,0.3)]',
  secondary: 'bg-secondary/20 text-secondary hover:bg-secondary/30 hover:shadow-[0_0_20px_rgba(59,130,246,0.3)]',
  ghost: 'bg-white/5 text-text-secondary hover:bg-white/10 hover:text-text',
  danger: 'bg-coral/20 text-coral hover:bg-coral/30 hover:shadow-[0_0_20px_rgba(244,63,94,0.3)]',
  success: 'bg-accent/20 text-accent hover:bg-accent/30 hover:shadow-[0_0_20px_rgba(20,184,166,0.3)]',
  accent: 'bg-orange/20 text-orange hover:bg-orange/30 hover:shadow-[0_0_20px_rgba(249,115,22,0.3)]',
};

const sizeStyles: Record<IconButtonSize, { button: string; icon: string }> = {
  xs: { button: 'w-6 h-6', icon: 'w-3 h-3' },
  sm: { button: 'w-8 h-8', icon: 'w-4 h-4' },
  md: { button: 'w-10 h-10', icon: 'w-5 h-5' },
  lg: { button: 'w-12 h-12', icon: 'w-6 h-6' },
};

const IconButton = forwardRef<HTMLButtonElement, IconButtonProps>(
  (
    {
      variant = 'ghost',
      size = 'md',
      icon,
      label,
      loading = false,
      rounded = true,
      className = '',
      disabled,
      ...props
    },
    ref
  ) => {
    const baseStyles = `
      inline-flex items-center justify-center
      transition-all duration-200 ease-out
      focus:outline-none focus:ring-2 focus:ring-primary/50 focus:ring-offset-2 focus:ring-offset-background
      disabled:opacity-50 disabled:cursor-not-allowed disabled:hover:shadow-none
    `;

    return (
      <button
        ref={ref}
        disabled={disabled || loading}
        className={`
          ${baseStyles}
          ${variantStyles[variant]}
          ${sizeStyles[size].button}
          ${rounded ? 'rounded-full' : 'rounded-xl'}
          ${className}
        `}
        aria-label={label}
        title={label}
        {...props}
      >
        {loading ? (
          <svg
            className={`${sizeStyles[size].icon} animate-spin`}
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
        ) : (
          <span className={sizeStyles[size].icon}>{icon}</span>
        )}
      </button>
    );
  }
);

IconButton.displayName = 'IconButton';

export default IconButton;
