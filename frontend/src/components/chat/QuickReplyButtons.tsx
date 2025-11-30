/**
 * QuickReplyButtons Component
 *
 * Displays quick reply buttons below AI messages for common responses.
 * Supports single-select and multi-select modes.
 *
 * Features:
 * - Glass-morphism styling
 * - Glow effect on hover
 * - Multi-select support
 * - Icons support
 * - Responsive grid layout
 */
import { FC, useState } from 'react';
import type { QuickReply } from '../../types/onboarding';

interface QuickReplyButtonsProps {
  replies: QuickReply[];
  onSelect: (value: any) => void;
  multiSelect?: boolean;
  selectedValues?: any[];
  onOtherSelected?: () => void;  // Called when "Other" is selected - allows user to type custom value
}

const QuickReplyButtons: FC<QuickReplyButtonsProps> = ({
  replies,
  onSelect,
  multiSelect = false,
  selectedValues = [],
  onOtherSelected,
}) => {
  const [selected, setSelected] = useState<Set<any>>(new Set(selectedValues));

  const handleClick = (reply: QuickReply) => {
    // Check if "Other" was selected
    if (reply.value === '__other__') {
      if (onOtherSelected) {
        onOtherSelected();
      }
      return;
    }

    if (multiSelect) {
      // In multi-select mode, just toggle selection state
      // The actual submission happens when user clicks "Continue" button
      const newSelected = new Set(selected);
      if (newSelected.has(reply.value)) {
        newSelected.delete(reply.value);
      } else {
        newSelected.add(reply.value);
      }
      setSelected(newSelected);
    } else {
      // Single-select: immediately trigger send
      onSelect(reply.value);
    }
  };

  const isSelected = (value: any) => selected.has(value);

  return (
    <div className="flex flex-wrap gap-2 mt-3">
      {replies.map((reply, index) => (
        <button
          key={`${reply.value}-${index}`}
          onClick={() => handleClick(reply)}
          className={`
            px-3 py-1.5 rounded-full text-xs font-medium
            transition-all duration-200
            ${
              isSelected(reply.value)
                ? 'bg-primary/30 border-2 border-primary text-primary shadow-[0_0_15px_rgba(6,182,212,0.4)]'
                : 'bg-white/10 border border-primary/50 text-text-secondary hover:bg-primary/20 hover:border-primary hover:text-text'
            }
          `}
        >
          {reply.icon && <span className="mr-1">{reply.icon}</span>}
          {reply.label}
        </button>
      ))}

      {/* Multi-select confirm button */}
      {multiSelect && selected.size > 0 && (
        <button
          onClick={() => onSelect(Array.from(selected))}
          className="
            px-4 py-1.5 rounded-full text-xs font-bold
            bg-gradient-to-r from-primary to-secondary
            text-white
            shadow-[0_0_20px_rgba(6,182,212,0.5)]
            hover:shadow-[0_0_30px_rgba(6,182,212,0.7)]
            transition-all duration-200
          "
        >
          Continue ({selected.size} selected)
        </button>
      )}
    </div>
  );
};

export default QuickReplyButtons;
