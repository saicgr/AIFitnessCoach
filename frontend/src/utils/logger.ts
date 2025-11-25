/**
 * Centralized logging utility for the frontend.
 *
 * Usage:
 *   import { logger } from '../utils/logger';
 *   logger.info('api', 'User created', { userId: 1 });
 *   logger.error('store', 'Failed to load workouts', error);
 */

type LogLevel = 'debug' | 'info' | 'warn' | 'error';

interface LogEntry {
  timestamp: string;
  level: LogLevel;
  module: string;
  message: string;
  data?: unknown;
}

const LOG_LEVELS: Record<LogLevel, number> = {
  debug: 0,
  info: 1,
  warn: 2,
  error: 3,
};

// Set minimum log level (can be changed for production)
const MIN_LOG_LEVEL: LogLevel = 'debug';

function formatTimestamp(): string {
  const now = new Date();
  return now.toISOString().replace('T', ' ').substring(0, 19);
}

function formatMessage(entry: LogEntry): string {
  return `[${entry.timestamp}] [${entry.level.toUpperCase()}] [${entry.module}] ${entry.message}`;
}

function shouldLog(level: LogLevel): boolean {
  return LOG_LEVELS[level] >= LOG_LEVELS[MIN_LOG_LEVEL];
}

function log(level: LogLevel, module: string, message: string, data?: unknown): void {
  if (!shouldLog(level)) return;

  const entry: LogEntry = {
    timestamp: formatTimestamp(),
    level,
    module,
    message,
    data,
  };

  const formattedMessage = formatMessage(entry);

  switch (level) {
    case 'debug':
      if (data !== undefined) {
        console.debug(formattedMessage, data);
      } else {
        console.debug(formattedMessage);
      }
      break;
    case 'info':
      if (data !== undefined) {
        console.info(formattedMessage, data);
      } else {
        console.info(formattedMessage);
      }
      break;
    case 'warn':
      if (data !== undefined) {
        console.warn(formattedMessage, data);
      } else {
        console.warn(formattedMessage);
      }
      break;
    case 'error':
      if (data !== undefined) {
        console.error(formattedMessage, data);
      } else {
        console.error(formattedMessage);
      }
      break;
  }
}

export const logger = {
  debug: (module: string, message: string, data?: unknown) => log('debug', module, message, data),
  info: (module: string, message: string, data?: unknown) => log('info', module, message, data),
  warn: (module: string, message: string, data?: unknown) => log('warn', module, message, data),
  error: (module: string, message: string, data?: unknown) => log('error', module, message, data),
};

// Create a module-specific logger
export function createLogger(module: string) {
  return {
    debug: (message: string, data?: unknown) => log('debug', module, message, data),
    info: (message: string, data?: unknown) => log('info', module, message, data),
    warn: (message: string, data?: unknown) => log('warn', module, message, data),
    error: (message: string, data?: unknown) => log('error', module, message, data),
  };
}

export default logger;
