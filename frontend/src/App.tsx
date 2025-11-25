import { Routes, Route, Navigate } from 'react-router-dom';
import { useAppStore } from './store';
import Onboarding from './pages/Onboarding';
import Home from './pages/Home';
import WorkoutDetails from './pages/WorkoutDetails';
import ActiveWorkout from './pages/ActiveWorkout';
import Chat from './pages/Chat';
import Settings from './pages/Settings';

function App() {
  const { user } = useAppStore();

  // Check for valid user with proper structure
  const isValidUser = user && typeof user.id === 'number' && user.onboarding_completed === true;

  // Log user state for debugging
  console.log('🔐 App: User state:', { user, isValidUser });

  return (
    <Routes>
      <Route
        path="/"
        element={isValidUser ? <Home /> : <Navigate to="/onboarding" replace />}
      />
      <Route path="/onboarding" element={<Onboarding />} />
      <Route path="/workout/:id" element={<WorkoutDetails />} />
      <Route path="/workout/:id/active" element={<ActiveWorkout />} />
      <Route path="/chat" element={<Chat />} />
      <Route path="/settings" element={<Settings />} />
    </Routes>
  );
}

export default App;
