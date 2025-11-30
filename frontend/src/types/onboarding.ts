/**
 * Shared types for conversational onboarding
 */

export interface QuickReply {
  label: string;
  value: any;
  icon?: string;
}

export interface ConversationalMessage {
  role: 'user' | 'assistant';
  content: string;
  timestamp: string;
  quickReplies?: QuickReply[];
  component?: 'day_picker' | 'unit_input' | 'health_checklist';
  extractedData?: Record<string, any>;
}
