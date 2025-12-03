import { motion } from 'framer-motion';
import { useAppStore } from '../../store';

export default function ChatWidgetToggle() {
  const { chatWidgetState, setChatWidgetOpen } = useAppStore();

  const handleClick = () => {
    setChatWidgetOpen(true);
  };

  return (
    <motion.button
      onClick={handleClick}
      className="relative w-14 h-14 rounded-full bg-gradient-to-br from-secondary to-primary shadow-lg flex items-center justify-center"
      style={{
        boxShadow: '0 4px 20px rgba(147, 51, 234, 0.4)',
      }}
      whileHover={{ scale: 1.1 }}
      whileTap={{ scale: 0.95 }}
      initial={{ scale: 0, opacity: 0 }}
      animate={{ scale: 1, opacity: 1 }}
      exit={{ scale: 0, opacity: 0 }}
      transition={{ type: 'spring', stiffness: 260, damping: 20 }}
    >
      {/* Chat Icon */}
      <svg
        className="w-6 h-6 text-white"
        fill="none"
        stroke="currentColor"
        viewBox="0 0 24 24"
      >
        <path
          strokeLinecap="round"
          strokeLinejoin="round"
          strokeWidth={2}
          d="M8 12h.01M12 12h.01M16 12h.01M21 12c0 4.418-4.03 8-9 8a9.863 9.863 0 01-4.255-.949L3 20l1.395-3.72C3.512 15.042 3 13.574 3 12c0-4.418 4.03-8 9-8s9 3.582 9 8z"
        />
      </svg>

      {/* Unread Badge */}
      {chatWidgetState.hasUnreadMessages && (
        <motion.span
          className="absolute -top-1 -right-1 w-4 h-4 bg-red-500 rounded-full"
          initial={{ scale: 0 }}
          animate={{ scale: 1 }}
          transition={{ type: 'spring', stiffness: 500, damping: 25 }}
        >
          <span className="absolute inset-0 rounded-full bg-red-500 animate-ping opacity-75" />
        </motion.span>
      )}
    </motion.button>
  );
}
