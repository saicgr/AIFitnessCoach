import { StrictMode } from 'react';
import { createRoot } from 'react-dom/client';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { BrowserRouter } from 'react-router-dom';
import './index.css';
import App from './App.tsx';

// Check for session reset marker from start.sh
// This clears localStorage when the server restarts
async function checkSessionReset() {
  try {
    const response = await fetch('/session-reset.json?t=' + Date.now());
    if (response.ok) {
      const data = await response.json();
      const lastResetVersion = localStorage.getItem('session-reset-version');

      // If version changed, clear localStorage (new server start)
      if (lastResetVersion !== data.version) {
        console.log('🔄 New session detected, clearing localStorage...');
        // Clear all app data but save the new reset version
        const keysToRemove = [];
        for (let i = 0; i < localStorage.length; i++) {
          const key = localStorage.key(i);
          if (key && key !== 'session-reset-version') {
            keysToRemove.push(key);
          }
        }
        keysToRemove.forEach(key => localStorage.removeItem(key));

        // Save the new version to prevent clearing again on refresh
        localStorage.setItem('session-reset-version', data.version);
        console.log('✅ Session cleared, ready for fresh login');
      }
    }
  } catch {
    // No reset marker found or fetch failed - that's fine, continue normally
  }
}

// Run session check before rendering
checkSessionReset();

const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      staleTime: 1000 * 60 * 5, // 5 minutes
      retry: 1,
    },
  },
});

createRoot(document.getElementById('root')!).render(
  <StrictMode>
    <QueryClientProvider client={queryClient}>
      <BrowserRouter>
        <App />
      </BrowserRouter>
    </QueryClientProvider>
  </StrictMode>
);
