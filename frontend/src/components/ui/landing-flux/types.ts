export interface LandingFluxProps {
  className?: string;
  rows?: number;
  barHeight?: number;
  gap?: number;
  color?: string;
  disableMarquee?: boolean;
}

export type ElementType = 'bar' | 'star' | 'circle' | 'broken' | 'pill' | 'invisible';

export interface FluxElement {
  type: ElementType;
  x: number;
  width: number;
  opacity: number;
  fadeDelay: number;
  fadeStarted: boolean;
  // star-specific
  rotation?: number;
  targetRotation?: number;
  rotationTimer?: number;
  // circle-specific
  label?: string;
  positive?: boolean;
  hoverProgress?: number;
  chipWidth?: number;
  // broken-specific
  gapOpen?: number;
}

export interface RowState {
  elements: FluxElement[];
  offset: number;
  speed: number;
  direction: number;
  totalWidth: number;
  hoveredCircle: number | null;
  hoverBarProgress: number;
  hoverBarX: number;
  hoverBarWidth: number;
  hoverBarActive: boolean;
}
