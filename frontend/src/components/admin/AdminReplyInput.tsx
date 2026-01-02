/**
 * AdminReplyInput - Input component for admin to reply to chats
 */
import { useState, useRef, useEffect, type KeyboardEvent } from 'react';

interface AdminReplyInputProps {
  onSend: (message: string) => void;
  disabled?: boolean;
  placeholder?: string;
  suggestedResponse?: string;
}

export default function AdminReplyInput({
  onSend,
  disabled = false,
  placeholder = 'Type your reply...',
  suggestedResponse,
}: AdminReplyInputProps) {
  const [message, setMessage] = useState('');
  const textareaRef = useRef<HTMLTextAreaElement>(null);

  // Auto-resize textarea
  useEffect(() => {
    if (textareaRef.current) {
      textareaRef.current.style.height = 'auto';
      textareaRef.current.style.height = `${Math.min(textareaRef.current.scrollHeight, 150)}px`;
    }
  }, [message]);

  const handleSend = () => {
    if (message.trim() && !disabled) {
      onSend(message.trim());
      setMessage('');
    }
  };

  const handleKeyDown = (e: KeyboardEvent<HTMLTextAreaElement>) => {
    if (e.key === 'Enter' && !e.shiftKey) {
      e.preventDefault();
      handleSend();
    }
  };

  const useSuggestedResponse = () => {
    if (suggestedResponse) {
      setMessage(suggestedResponse);
      textareaRef.current?.focus();
    }
  };

  return (
    <div className="border-t border-white/10 p-4">
      {/* Suggested Response */}
      {suggestedResponse && (
        <div className="mb-3 p-3 rounded-lg bg-purple-500/10 border border-purple-500/20">
          <div className="flex items-start justify-between gap-2">
            <div className="flex-1">
              <div className="flex items-center gap-2 text-xs text-purple-400 mb-1">
                <svg className="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9.663 17h4.673M12 3v1m6.364 1.636l-.707.707M21 12h-1M4 12H3m3.343-5.657l-.707-.707m2.828 9.9a5 5 0 117.072 0l-.548.547A3.374 3.374 0 0014 18.469V19a2 2 0 11-4 0v-.531c0-.895-.356-1.754-.988-2.386l-.548-.547z" />
                </svg>
                <span>AI Suggested Response</span>
              </div>
              <p className="text-sm text-text-secondary line-clamp-2">{suggestedResponse}</p>
            </div>
            <button
              onClick={useSuggestedResponse}
              className="flex-shrink-0 px-3 py-1.5 rounded-lg bg-purple-500/20 text-purple-400 text-sm hover:bg-purple-500/30 transition-colors"
            >
              Use
            </button>
          </div>
        </div>
      )}

      {/* Input Area */}
      <div className="flex items-end gap-3">
        {/* Quick Actions */}
        <div className="flex items-center gap-1 pb-2">
          <button
            className="p-2 rounded-lg text-text-secondary hover:bg-white/10 transition-colors"
            title="Canned responses"
          >
            <svg className="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4 6h16M4 10h16M4 14h16M4 18h16" />
            </svg>
          </button>
          <button
            className="p-2 rounded-lg text-text-secondary hover:bg-white/10 transition-colors"
            title="Attach file"
          >
            <svg className="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15.172 7l-6.586 6.586a2 2 0 102.828 2.828l6.414-6.586a4 4 0 00-5.656-5.656l-6.415 6.585a6 6 0 108.486 8.486L20.5 13" />
            </svg>
          </button>
        </div>

        {/* Text Input */}
        <div className="flex-1 relative">
          <textarea
            ref={textareaRef}
            value={message}
            onChange={(e) => setMessage(e.target.value)}
            onKeyDown={handleKeyDown}
            placeholder={placeholder}
            disabled={disabled}
            rows={1}
            className="w-full bg-white/5 border border-white/10 rounded-xl px-4 py-3 text-text placeholder:text-text-muted resize-none focus:outline-none focus:border-primary focus:ring-2 focus:ring-primary/30 disabled:opacity-50 disabled:cursor-not-allowed transition-all"
          />
        </div>

        {/* Send Button */}
        <button
          onClick={handleSend}
          disabled={!message.trim() || disabled}
          className="p-3 rounded-xl bg-gradient-to-r from-primary to-primary-dark text-white shadow-[0_0_20px_rgba(16,185,129,0.4)] hover:shadow-[0_0_30px_rgba(16,185,129,0.5)] disabled:opacity-50 disabled:cursor-not-allowed disabled:shadow-none transition-all"
        >
          <svg className="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 19l9 2-9-18-9 18 9-2zm0 0v-8" />
          </svg>
        </button>
      </div>

      {/* Helper text */}
      <p className="text-xs text-text-muted mt-2">
        Press Enter to send, Shift + Enter for new line
      </p>
    </div>
  );
}
