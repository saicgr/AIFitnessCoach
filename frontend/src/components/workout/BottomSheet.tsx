import { useState, useRef, useEffect, useCallback, type ReactNode } from 'react';

interface BottomSheetProps {
  isExpanded: boolean;
  onExpandedChange: (expanded: boolean) => void;
  collapsedHeight?: number;
  expandedHeight?: number;
  children: ReactNode;
  collapsedContent?: ReactNode;
}

export default function BottomSheet({
  isExpanded,
  onExpandedChange,
  collapsedHeight = 220,
  expandedHeight,
  children,
  collapsedContent,
}: BottomSheetProps) {
  const sheetRef = useRef<HTMLDivElement>(null);
  const [isDragging, setIsDragging] = useState(false);
  const [dragStartY, setDragStartY] = useState(0);
  const [currentTranslate, setCurrentTranslate] = useState(0);
  const [maxHeight, setMaxHeight] = useState(0);

  // Calculate max height on mount
  useEffect(() => {
    const height = expandedHeight || window.innerHeight * 0.85;
    setMaxHeight(height);
  }, [expandedHeight]);

  const handleDragStart = useCallback((clientY: number) => {
    setIsDragging(true);
    setDragStartY(clientY);
    setCurrentTranslate(0);
  }, []);

  const handleDragMove = useCallback((clientY: number) => {
    if (!isDragging) return;
    const delta = dragStartY - clientY;
    setCurrentTranslate(delta);
  }, [isDragging, dragStartY]);

  const handleDragEnd = useCallback(() => {
    if (!isDragging) return;
    setIsDragging(false);

    // If dragged more than 50px up, expand; if dragged more than 50px down, collapse
    const threshold = 50;
    if (currentTranslate > threshold && !isExpanded) {
      onExpandedChange(true);
    } else if (currentTranslate < -threshold && isExpanded) {
      onExpandedChange(false);
    }
    setCurrentTranslate(0);
  }, [isDragging, currentTranslate, isExpanded, onExpandedChange]);

  // Touch handlers
  const handleTouchStart = (e: React.TouchEvent) => {
    handleDragStart(e.touches[0].clientY);
  };

  const handleTouchMove = (e: React.TouchEvent) => {
    handleDragMove(e.touches[0].clientY);
  };

  const handleTouchEnd = () => {
    handleDragEnd();
  };

  // Mouse handlers
  const handleMouseDown = (e: React.MouseEvent) => {
    e.preventDefault();
    handleDragStart(e.clientY);
  };

  useEffect(() => {
    if (!isDragging) return;

    const handleMouseMove = (e: MouseEvent) => {
      handleDragMove(e.clientY);
    };

    const handleMouseUp = () => {
      handleDragEnd();
    };

    document.addEventListener('mousemove', handleMouseMove);
    document.addEventListener('mouseup', handleMouseUp);

    return () => {
      document.removeEventListener('mousemove', handleMouseMove);
      document.removeEventListener('mouseup', handleMouseUp);
    };
  }, [isDragging, handleDragMove, handleDragEnd]);

  // Calculate current height during drag
  const getSheetHeight = () => {
    const baseHeight = isExpanded ? maxHeight : collapsedHeight;
    if (isDragging) {
      const newHeight = baseHeight + currentTranslate;
      return Math.max(collapsedHeight, Math.min(maxHeight, newHeight));
    }
    return baseHeight;
  };

  return (
    <div
      ref={sheetRef}
      className={`
        fixed left-0 right-0 bottom-0 z-40
        bg-surface/95 backdrop-blur-xl
        border-t border-white/10
        rounded-t-3xl
        shadow-[0_-10px_40px_rgba(0,0,0,0.3)]
        ${isDragging ? '' : 'transition-all duration-300 ease-out'}
      `}
      style={{
        height: `${getSheetHeight()}px`,
      }}
    >
      {/* Drag Handle */}
      <div
        className="flex items-center justify-center py-3 cursor-grab active:cursor-grabbing touch-none"
        onTouchStart={handleTouchStart}
        onTouchMove={handleTouchMove}
        onTouchEnd={handleTouchEnd}
        onMouseDown={handleMouseDown}
      >
        <div className="w-10 h-1.5 bg-white/30 rounded-full" />
      </div>

      {/* Content */}
      <div className="flex-1 overflow-y-auto px-4 pb-4" style={{ maxHeight: `${getSheetHeight() - 40}px` }}>
        {isExpanded ? children : (collapsedContent || children)}
      </div>
    </div>
  );
}
