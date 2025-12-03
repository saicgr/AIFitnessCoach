import { useEffect } from 'react';
import { Routes, Route, Navigate } from 'react-router-dom';
import { useAppStore } from './store';
import { supabase } from './lib/supabase';
import Landing from './pages/Landing';
import Onboarding from './pages/Onboarding';
import OnboardingSelector from './pages/OnboardingSelector';
import ConversationalOnboarding from './pages/ConversationalOnboarding';
import Home from './pages/Home';
import WorkoutDetails from './pages/WorkoutDetails';
import ActiveWorkout from './pages/ActiveWorkout';
import Chat from './pages/Chat';
import Settings from './pages/Settings';
import DemoLogin from './pages/DemoLogin';
import AuthCallback from './pages/AuthCallback';
import Profile from './pages/Profile';
import Metrics from './pages/Metrics';
import Nutrition from './pages/Nutrition';
import Library from './pages/Library';
import Achievements from './pages/Achievements';
import ChatWidget from './components/chat/ChatWidget';

function App() {
  const { user, setSession, setUser } = useAppStore();

  // Listen for auth state changes
  useEffect(() => {
    const { data: { subscription } } = supabase.auth.onAuthStateChange(
      async (event, session) => {
        console.log('🔐 Auth state changed:', event, session?.user?.id);

        if (event === 'SIGNED_OUT') {
          setSession(null);
          setUser(null);
        } else if (session) {
          setSession(session);
        }
      }
    );

    return () => {
      subscription.unsubscribe();
    };
  }, [setSession, setUser]);

  // Check for valid user with proper structure
  const isValidUser = user && (typeof user.id === 'number' || typeof user.id === 'string') && user.onboarding_completed === true;

  // Log user state for debugging
  console.log('🔐 App: User state:', { user, isValidUser });

  return (
    <>
      <Routes>
        {/* Public landing page */}
        <Route path="/" element={<Landing />} />
        {/* Protected home (dashboard) */}
        <Route
          path="/home"
          element={isValidUser ? <Home /> : <Navigate to="/login" replace />}
        />
        <Route path="/login" element={<DemoLogin />} />
        <Route path="/auth/callback" element={<AuthCallback />} />
        <Route
          path="/onboarding/selector"
          element={
            user?.onboarding_completed
              ? <Navigate to="/home" replace />
              : <OnboardingSelector />
          }
        />
        <Route
          path="/onboarding/chat"
          element={
            user?.onboarding_completed
              ? <Navigate to="/home" replace />
              : <ConversationalOnboarding />
          }
        />
        <Route
          path="/onboarding"
          element={
            user?.onboarding_completed
              ? <Navigate to="/home" replace />
              : <Onboarding />
          }
        />
        <Route path="/workout/:id" element={<WorkoutDetails />} />
        <Route path="/workout/:id/active" element={<ActiveWorkout />} />
        <Route path="/chat" element={<Chat />} />
        <Route path="/settings" element={<Settings />} />
        <Route path="/profile" element={<Profile />} />
        <Route path="/metrics" element={<Metrics />} />
        <Route path="/nutrition" element={<Nutrition />} />
        <Route path="/library" element={<Library />} />
        <Route path="/achievements" element={<Achievements />} />
      </Routes>
      {/* Global Chat Widget - renders via portal, only for authenticated users */}
      {isValidUser && <ChatWidget />}
    </>
  );
}

export default App;
