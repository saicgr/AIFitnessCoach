/**
 * MessageBubble Component
 *
 * WhatsApp-style message bubble for conversational onboarding.
 * Displays user and AI messages with proper styling and animations.
 *
 * Features:
 * - Different styles for user vs AI messages
 * - AI avatar with gradient
 * - Smooth fade-in animations
 * - Glass-morphism design
 */
import type { FC } from 'react';

interface MessageBubbleProps {
  role: 'user' | 'assistant';
  content: string;
  timestamp?: string;
}

const MessageBubble: FC<MessageBubbleProps> = ({ role, content, timestamp }) => {
  const isUser = role === 'user';

  return (
    <div
      className={`flex ${isUser ? 'justify-end' : 'justify-start'} mb-4 animate-fade-in`}
      style={{
        animation: 'fadeIn 0.3s ease-in',
      }}
    >
      {/* AI Avatar */}
      {!isUser && (
        <div className="w-10 h-10 rounded-full bg-gradient-to-br from-primary to-secondary flex items-center justify-center mr-3 shadow-[0_0_20px_rgba(6,182,212,0.4)] flex-shrink-0">
          <svg
            className="w-5 h-5 text-white"
            fill="none"
            stroke="currentColor"
            viewBox="0 0 24 24"
          >
            <path
              strokeLinecap="round"
              strokeLinejoin="round"
              strokeWidth={2}
              d="M5 3v4M3 5h4M6 17v4m-2-2h4m5-16l2.286 6.857L21 12l-5.714 2.143L13 21l-2.286-6.857L5 12l5.714-2.143L13 3z"
            />
          </svg>
        </div>
      )}

      {/* Message Bubble */}
      <div
        className={`
          max-w-[75%] px-4 py-3 rounded-2xl
          ${
            isUser
              ? 'bg-gradient-to-br from-primary to-primary-dark text-white rounded-br-sm shadow-[0_0_20px_rgba(6,182,212,0.3)]'
              : 'bg-white/10 backdrop-blur-md border border-white/20 text-text rounded-bl-sm'
          }
        `}
      >
        <p className="text-sm leading-relaxed whitespace-pre-wrap break-words">
          {content}
        </p>

        {/* Timestamp (optional) */}
        {timestamp && (
          <div
            className={`text-xs mt-1 ${
              isUser ? 'text-white/70' : 'text-text-secondary/70'
            }`}
          >
            {new Date(timestamp).toLocaleTimeString([], {
              hour: '2-digit',
              minute: '2-digit',
            })}
          </div>
        )}
      </div>
    </div>
  );
};

export default MessageBubble;
