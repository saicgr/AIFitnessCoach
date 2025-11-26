import type { ReactNode } from 'react';

interface GlassCardProps {
  children: ReactNode;
  className?: string;
  variant?: 'default' | 'elevated' | 'glow';
  glowColor?: 'primary' | 'secondary' | 'accent' | 'orange' | 'magenta';
  onClick?: () => void;
  hoverable?: boolean;
}

const glowClasses = {
  primary: 'hover:shadow-[0_0_30px_rgba(6,182,212,0.3)]',
  secondary: 'hover:shadow-[0_0_30px_rgba(59,130,246,0.3)]',
  accent: 'hover:shadow-[0_0_30px_rgba(20,184,166,0.3)]',
  orange: 'hover:shadow-[0_0_30px_rgba(249,115,22,0.3)]',
  magenta: 'hover:shadow-[0_0_30px_rgba(236,72,153,0.3)]',
};

const activeGlowClasses = {
  primary: 'shadow-[0_0_20px_rgba(6,182,212,0.4),0_0_40px_rgba(6,182,212,0.2)]',
  secondary: 'shadow-[0_0_20px_rgba(59,130,246,0.4),0_0_40px_rgba(59,130,246,0.2)]',
  accent: 'shadow-[0_0_20px_rgba(20,184,166,0.4),0_0_40px_rgba(20,184,166,0.2)]',
  orange: 'shadow-[0_0_20px_rgba(249,115,22,0.4),0_0_40px_rgba(249,115,22,0.2)]',
  magenta: 'shadow-[0_0_20px_rgba(236,72,153,0.4),0_0_40px_rgba(236,72,153,0.2)]',
};

export default function GlassCard({
  children,
  className = '',
  variant = 'default',
  glowColor = 'primary',
  onClick,
  hoverable = false,
}: GlassCardProps) {
  const baseClasses = `
    relative overflow-hidden rounded-2xl
    bg-gradient-to-br from-white/10 to-white/5
    backdrop-blur-xl
    border border-white/10
    transition-all duration-300 ease-out
  `;

  const variantClasses = {
    default: 'shadow-[0_8px_32px_rgba(0,0,0,0.3),inset_0_1px_0_rgba(255,255,255,0.1)]',
    elevated: 'shadow-[0_12px_40px_rgba(0,0,0,0.4),inset_0_1px_0_rgba(255,255,255,0.15)]',
    glow: activeGlowClasses[glowColor],
  };

  const hoverClasses = hoverable
    ? `cursor-pointer hover:-translate-y-1 ${glowClasses[glowColor]}`
    : '';

  return (
    <div
      className={`${baseClasses} ${variantClasses[variant]} ${hoverClasses} ${className}`}
      onClick={onClick}
    >
      {/* Top light edge effect */}
      <div className="absolute inset-x-0 top-0 h-px bg-gradient-to-r from-transparent via-white/20 to-transparent" />

      {children}
    </div>
  );
}
