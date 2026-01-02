/**
 * ChatMessageList - Displays chat conversation messages
 */
import { useEffect, useRef } from 'react';
import type { LiveChatMessage } from '../../store/adminStore';

interface ChatMessageListProps {
  messages: LiveChatMessage[];
  currentAdminId?: string;
}

export default function ChatMessageList({ messages, currentAdminId }: ChatMessageListProps) {
  const messagesEndRef = useRef<HTMLDivElement>(null);

  // Auto-scroll to bottom when new messages arrive
  useEffect(() => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
  }, [messages]);

  const formatTime = (dateString: string) => {
    const date = new Date(dateString);
    return date.toLocaleTimeString('en-US', {
      hour: 'numeric',
      minute: '2-digit',
      hour12: true,
    });
  };

  const formatDate = (dateString: string) => {
    const date = new Date(dateString);
    const today = new Date();
    const yesterday = new Date(today);
    yesterday.setDate(yesterday.getDate() - 1);

    if (date.toDateString() === today.toDateString()) {
      return 'Today';
    } else if (date.toDateString() === yesterday.toDateString()) {
      return 'Yesterday';
    } else {
      return date.toLocaleDateString('en-US', {
        weekday: 'short',
        month: 'short',
        day: 'numeric',
      });
    }
  };

  // Group messages by date
  const groupedMessages: { date: string; messages: LiveChatMessage[] }[] = [];
  let currentDate = '';

  messages.forEach((message) => {
    const messageDate = formatDate(message.created_at);
    if (messageDate !== currentDate) {
      currentDate = messageDate;
      groupedMessages.push({ date: messageDate, messages: [message] });
    } else {
      groupedMessages[groupedMessages.length - 1].messages.push(message);
    }
  });

  return (
    <div className="flex-1 overflow-y-auto p-4 space-y-4">
      {groupedMessages.map((group, groupIndex) => (
        <div key={groupIndex}>
          {/* Date separator */}
          <div className="flex items-center gap-4 my-4">
            <div className="flex-1 h-px bg-white/10" />
            <span className="text-xs text-text-muted">{group.date}</span>
            <div className="flex-1 h-px bg-white/10" />
          </div>

          {/* Messages for this date */}
          <div className="space-y-3">
            {group.messages.map((message) => {
              const isUser = message.sender_type === 'user';
              const isAI = message.sender_type === 'ai';
              const isCurrentAdmin =
                message.sender_type === 'admin' && message.sender_id === currentAdminId;

              return (
                <div
                  key={message.id}
                  className={`flex ${isUser ? 'justify-start' : 'justify-end'}`}
                >
                  <div
                    className={`max-w-[70%] ${
                      isUser
                        ? 'order-2'
                        : isAI
                        ? 'order-1'
                        : 'order-1'
                    }`}
                  >
                    {/* Sender name */}
                    <div
                      className={`text-xs text-text-muted mb-1 ${
                        isUser ? 'text-left' : 'text-right'
                      }`}
                    >
                      {isAI ? 'AI Assistant' : message.sender_name}
                    </div>

                    {/* Message bubble */}
                    <div
                      className={`px-4 py-3 rounded-2xl ${
                        isUser
                          ? 'bg-white/10 text-text rounded-bl-md'
                          : isAI
                          ? 'bg-purple-500/20 text-purple-100 rounded-br-md border border-purple-500/30'
                          : isCurrentAdmin
                          ? 'bg-primary/20 text-primary-light rounded-br-md border border-primary/30'
                          : 'bg-blue-500/20 text-blue-100 rounded-br-md border border-blue-500/30'
                      }`}
                    >
                      <p className="text-sm whitespace-pre-wrap">{message.content}</p>
                    </div>

                    {/* Timestamp */}
                    <div
                      className={`text-xs text-text-muted mt-1 ${
                        isUser ? 'text-left' : 'text-right'
                      }`}
                    >
                      {formatTime(message.created_at)}
                      {message.read_at && !isUser && (
                        <span className="ml-2 text-green-400">Read</span>
                      )}
                    </div>
                  </div>

                  {/* Avatar for user messages */}
                  {isUser && (
                    <div className="w-8 h-8 rounded-full bg-gradient-to-br from-secondary to-accent flex items-center justify-center text-white text-xs font-medium mr-2 flex-shrink-0 order-1">
                      {message.sender_name.charAt(0).toUpperCase()}
                    </div>
                  )}
                </div>
              );
            })}
          </div>
        </div>
      ))}

      {/* Empty state */}
      {messages.length === 0 && (
        <div className="flex flex-col items-center justify-center h-full text-center">
          <svg
            className="w-16 h-16 text-text-muted mb-4"
            fill="none"
            viewBox="0 0 24 24"
            stroke="currentColor"
          >
            <path
              strokeLinecap="round"
              strokeLinejoin="round"
              strokeWidth={1}
              d="M8 12h.01M12 12h.01M16 12h.01M21 12c0 4.418-4.03 8-9 8a9.863 9.863 0 01-4.255-.949L3 20l1.395-3.72C3.512 15.042 3 13.574 3 12c0-4.418 4.03-8 9-8s9 3.582 9 8z"
            />
          </svg>
          <p className="text-text-muted">No messages yet</p>
        </div>
      )}

      {/* Scroll anchor */}
      <div ref={messagesEndRef} />
    </div>
  );
}
