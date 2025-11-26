import type { ReactNode } from 'react';

interface SelectionChipProps {
  children: ReactNode;
  selected?: boolean;
  onClick?: () => void;
  variant?: 'default' | 'primary' | 'secondary' | 'warning';
  size?: 'sm' | 'md';
  disabled?: boolean;
  icon?: ReactNode;
}

const variantStyles = {
  default: {
    base: 'border-white/10 bg-white/5 text-text-secondary',
    selected: 'border-primary bg-primary/20 text-primary',
    hover: 'hover:border-white/20 hover:bg-white/10',
  },
  primary: {
    base: 'border-white/10 bg-white/5 text-text-secondary',
    selected: 'border-primary bg-gradient-to-r from-primary to-primary-dark text-white shadow-[0_0_15px_rgba(6,182,212,0.3)]',
    hover: 'hover:border-primary/50 hover:bg-primary/10',
  },
  secondary: {
    base: 'border-white/10 bg-white/5 text-text-secondary',
    selected: 'border-accent bg-gradient-to-r from-accent to-accent-dark text-white shadow-[0_0_15px_rgba(20,184,166,0.3)]',
    hover: 'hover:border-accent/50 hover:bg-accent/10',
  },
  warning: {
    base: 'border-white/10 bg-white/5 text-text-secondary',
    selected: 'border-orange bg-orange/20 text-orange',
    hover: 'hover:border-orange/50 hover:bg-orange/10',
  },
};

export default function SelectionChip({
  children,
  selected = false,
  onClick,
  variant = 'default',
  size = 'md',
  disabled = false,
  icon,
}: SelectionChipProps) {
  const styles = variantStyles[variant];

  const sizeClasses = {
    sm: 'px-3 py-1.5 text-sm',
    md: 'px-4 py-2 text-sm',
  };

  return (
    <button
      type="button"
      onClick={onClick}
      disabled={disabled}
      className={`
        inline-flex items-center gap-2
        rounded-full
        border
        font-medium
        transition-all duration-200
        focus:outline-none focus-visible:ring-2 focus-visible:ring-primary focus-visible:ring-offset-2 focus-visible:ring-offset-background
        disabled:opacity-50 disabled:cursor-not-allowed
        ${sizeClasses[size]}
        ${selected ? styles.selected : styles.base}
        ${!selected && !disabled ? styles.hover : ''}
        ${selected ? 'scale-[1.02]' : 'scale-100'}
      `}
    >
      {icon && <span className="flex-shrink-0">{icon}</span>}
      {children}
      {selected && (
        <svg className="w-4 h-4" fill="currentColor" viewBox="0 0 20 20">
          <path
            fillRule="evenodd"
            d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z"
            clipRule="evenodd"
          />
        </svg>
      )}
    </button>
  );
}
