import { useAppStore } from '../../store';

export default function ChatWidgetHeader() {
  const { chatWidgetState, setChatWidgetOpen, setChatWidgetSize } = useAppStore();
  const { sizeMode } = chatWidgetState;

  const handleMinimize = () => {
    setChatWidgetOpen(false);
  };

  const handleRestore = () => {
    setChatWidgetSize('medium');
  };

  const handleMaximize = () => {
    setChatWidgetSize('maximized');
  };

  return (
    <div className="flex items-center justify-between p-3 border-b border-white/10 bg-background/80 backdrop-blur-xl rounded-t-2xl">
      {/* Title */}
      <div className="flex items-center gap-2">
        <div className="w-8 h-8 rounded-full bg-gradient-to-br from-secondary to-primary flex items-center justify-center">
          <svg
            className="w-4 h-4 text-white"
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
        </div>
        <div>
          <h3 className="text-white font-semibold text-sm">AI Coach</h3>
          <p className="text-white/50 text-xs">Always here to help</p>
        </div>
      </div>

      {/* Controls */}
      <div className="flex items-center gap-1">
        {/* Minimize (to FAB) */}
        <button
          onClick={handleMinimize}
          className="p-2 rounded-lg hover:bg-white/10 transition-colors text-white/60 hover:text-white"
          title="Minimize"
        >
          <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M20 12H4" />
          </svg>
        </button>

        {/* Restore/Medium */}
        {sizeMode === 'maximized' && (
          <button
            onClick={handleRestore}
            className="p-2 rounded-lg hover:bg-white/10 transition-colors text-white/60 hover:text-white"
            title="Restore"
          >
            <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path
                strokeLinecap="round"
                strokeLinejoin="round"
                strokeWidth={2}
                d="M8 4H6a2 2 0 00-2 2v2m0 4v2a2 2 0 002 2h2m4 0h2a2 2 0 002-2v-2m0-4V6a2 2 0 00-2-2h-2"
              />
            </svg>
          </button>
        )}

        {/* Maximize */}
        {sizeMode === 'medium' && (
          <button
            onClick={handleMaximize}
            className="p-2 rounded-lg hover:bg-white/10 transition-colors text-white/60 hover:text-white"
            title="Maximize"
          >
            <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path
                strokeLinecap="round"
                strokeLinejoin="round"
                strokeWidth={2}
                d="M4 8V4m0 0h4M4 4l5 5m11-1V4m0 0h-4m4 0l-5 5M4 16v4m0 0h4m-4 0l5-5m11 5l-5-5m5 5v-4m0 4h-4"
              />
            </svg>
          </button>
        )}

        {/* Close */}
        <button
          onClick={handleMinimize}
          className="p-2 rounded-lg hover:bg-red-500/20 transition-colors text-white/60 hover:text-red-400"
          title="Close"
        >
          <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path
              strokeLinecap="round"
              strokeLinejoin="round"
              strokeWidth={2}
              d="M6 18L18 6M6 6l12 12"
            />
          </svg>
        </button>
      </div>
    </div>
  );
}
