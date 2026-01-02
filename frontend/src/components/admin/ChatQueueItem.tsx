/**
 * ChatQueueItem - Individual chat item in the queue list
 */
import {
  type LiveChat,
  getCategoryColor,
  getPriorityColor,
  getStatusColor,
  formatWaitTime,
} from '../../store/adminStore';

interface ChatQueueItemProps {
  chat: LiveChat;
  isSelected: boolean;
  onClick: () => void;
}

export default function ChatQueueItem({ chat, isSelected, onClick }: ChatQueueItemProps) {
  const waitTimeSeconds = Math.floor(
    (Date.now() - new Date(chat.created_at).getTime()) / 1000
  );

  return (
    <button
      onClick={onClick}
      className={`w-full text-left p-4 rounded-xl transition-all ${
        isSelected
          ? 'bg-primary/20 border border-primary/30'
          : 'bg-white/5 hover:bg-white/10 border border-transparent'
      }`}
    >
      <div className="flex items-start gap-3">
        {/* User Avatar */}
        <div className="relative flex-shrink-0">
          <div className="w-10 h-10 rounded-full bg-gradient-to-br from-primary/50 to-secondary/50 flex items-center justify-center text-white font-medium">
            {chat.user.name.charAt(0).toUpperCase()}
          </div>
          {/* Status indicator */}
          <span
            className={`absolute -bottom-0.5 -right-0.5 w-3 h-3 rounded-full border-2 border-background ${
              chat.status === 'waiting'
                ? 'bg-yellow-500'
                : chat.status === 'active'
                ? 'bg-green-500'
                : chat.status === 'escalated'
                ? 'bg-red-500'
                : 'bg-gray-500'
            }`}
          />
        </div>

        {/* Chat Info */}
        <div className="flex-1 min-w-0">
          <div className="flex items-center gap-2 mb-1">
            <span className="font-medium text-text truncate">{chat.user.name}</span>
            {chat.unread_count > 0 && (
              <span className="flex-shrink-0 w-5 h-5 rounded-full bg-primary text-white text-xs flex items-center justify-center">
                {chat.unread_count}
              </span>
            )}
          </div>

          {/* Last message preview */}
          {chat.messages.length > 0 && (
            <p className="text-sm text-text-secondary truncate mb-2">
              {chat.messages[chat.messages.length - 1].content}
            </p>
          )}

          {/* Tags row */}
          <div className="flex items-center gap-2 flex-wrap">
            {/* Category */}
            <span className={`px-2 py-0.5 rounded text-xs font-medium ${getCategoryColor(chat.category)}`}>
              {chat.category}
            </span>

            {/* Status */}
            <span className={`px-2 py-0.5 rounded text-xs font-medium ${getStatusColor(chat.status)}`}>
              {chat.status}
            </span>

            {/* Priority indicator */}
            {chat.priority !== 'normal' && (
              <span className={`text-xs font-medium ${getPriorityColor(chat.priority)}`}>
                {chat.priority === 'urgent' && '!!!'}
                {chat.priority === 'high' && '!!'}
                {chat.priority === 'low' && '(low)'}
              </span>
            )}
          </div>
        </div>

        {/* Wait time */}
        <div className="flex-shrink-0 text-right">
          <p className="text-xs text-text-muted">{formatWaitTime(waitTimeSeconds)}</p>
          {chat.assigned_agent_name && (
            <p className="text-xs text-text-secondary mt-1 truncate max-w-[80px]">
              {chat.assigned_agent_name}
            </p>
          )}
        </div>
      </div>

      {/* AI Handoff indicator */}
      {chat.ai_handoff_context && (
        <div className="mt-3 p-2 rounded-lg bg-orange-500/10 border border-orange-500/20">
          <div className="flex items-center gap-2 text-xs text-orange-400">
            <svg className="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M13 10V3L4 14h7v7l9-11h-7z" />
            </svg>
            <span>AI Handoff: {chat.ai_handoff_context.reason}</span>
          </div>
        </div>
      )}
    </button>
  );
}
