import { useEffect } from 'react';
import { Routes, Route, Navigate } from 'react-router-dom';
import { useAppStore } from './store';
import { useAdminStore } from './store/adminStore';
import { supabase } from './lib/supabase';
import Landing from './pages/Landing';
import MarketingLanding from './pages/MarketingLanding';
import Features from './pages/Features';
import Pricing from './pages/Pricing';
import Lifetime from './pages/Lifetime';
import LifetimeSuccess from './pages/LifetimeSuccess';
import PrivacyPolicy from './pages/PrivacyPolicy';
import TermsOfService from './pages/TermsOfService';
import HealthDisclaimer from './pages/HealthDisclaimer';
import RefundPolicy from './pages/RefundPolicy';
import FAQ from './pages/FAQ';
import About from './pages/About';
import Architecture from './pages/Architecture';
import Contact from './pages/Contact';
import Changelog from './pages/Changelog';
import Roadmap from './pages/Roadmap';
import Waitlist from './pages/Waitlist';
import DeleteAccount from './pages/DeleteAccount';
import Invite from './pages/Invite';
import Onboarding from './pages/Onboarding';
import OnboardingSelector from './pages/OnboardingSelector';
import ConversationalOnboarding from './pages/ConversationalOnboarding';
import Home from './pages/Home';
import WorkoutDetails from './pages/WorkoutDetails';
import ActiveWorkout from './pages/ActiveWorkout';
import Chat from './pages/Chat';
import Settings from './pages/Settings';
// DemoLogin removed — all CTAs now link to Play Store
import AuthCallback from './pages/AuthCallback';
import Profile from './pages/Profile';
import Metrics from './pages/Metrics';
import Nutrition from './pages/Nutrition';
import Library from './pages/Library';
import Achievements from './pages/Achievements';
import PublicWorkout from './pages/PublicWorkout';
import GoogleHealthVs from './pages/vs/GoogleHealth';
import BestAiFitnessApps2026 from './pages/best/AiFitnessApps2026';
import BestCalorieTrackerApps2026 from './pages/best/CalorieTrackerApps2026';
import BestWorkoutGeneratorApps2026 from './pages/best/WorkoutGeneratorApps2026';
import BestFitbitAlternatives2026 from './pages/best/FitbitAlternatives2026';
import BestMyFitnessPalAlternatives2026 from './pages/best/MyFitnessPalAlternatives2026';
import ToolsIndex from './pages/tools';
import OneRmCalculator from './pages/tools/OneRmCalculator';
import TdeeCalculator from './pages/tools/TdeeCalculator';
import BmrCalculator from './pages/tools/BmrCalculator';
import BodyFatCalculator from './pages/tools/BodyFatCalculator';
import LeanBodyMassCalculator from './pages/tools/LeanBodyMassCalculator';
import BmiCalculator from './pages/tools/BmiCalculator';
import IdealWeightCalculator from './pages/tools/IdealWeightCalculator';
import HealthyWeightCalculator from './pages/tools/HealthyWeightCalculator';
import MacroCalculator from './pages/tools/MacroCalculator';
import AdaptiveMacroCalculator from './pages/tools/AdaptiveMacroCalculator';
import AdaptiveCalorieCalculator from './pages/tools/AdaptiveCalorieCalculator';
import ProteinPerMealCalculator from './pages/tools/ProteinPerMealCalculator';
import CarbCyclingCalculator from './pages/tools/CarbCyclingCalculator';
import CaloriesBurnedCalculator from './pages/tools/CaloriesBurnedCalculator';
import WilksCalculator from './pages/tools/WilksCalculator';
import DotsCalculator from './pages/tools/DotsCalculator';
import IpfGlCalculator from './pages/tools/IpfGlCalculator';
import SchwartzMaloneCalculator from './pages/tools/SchwartzMaloneCalculator';
import StrengthLevel from './pages/tools/StrengthLevel';
import PlateLoader from './pages/tools/PlateLoader';
import RirRpeConverter from './pages/tools/RirRpeConverter';
import Vo2MaxCalculator from './pages/tools/Vo2MaxCalculator';
import SweatRateCalculator from './pages/tools/SweatRateCalculator';
import PaceCalculator from './pages/tools/PaceCalculator';
import TargetHeartRateCalculator from './pages/tools/TargetHeartRateCalculator';
import WorkoutVolumeCalculator from './pages/tools/WorkoutVolumeCalculator';
import MesocycleVolumeCalculator from './pages/tools/MesocycleVolumeCalculator';
import DeloadWeekCalculator from './pages/tools/DeloadWeekCalculator';
import CutBulkDurationCalculator from './pages/tools/CutBulkDurationCalculator';
import TaperingCalculator from './pages/tools/TaperingCalculator';
import PhotoComparison from './pages/tools/PhotoComparison';
import PrCelebrationCard from './pages/tools/PrCelebrationCard';
import StreakCertificate from './pages/tools/StreakCertificate';
import WorkoutSummaryCard from './pages/tools/WorkoutSummaryCard';
import YearInFitnessWrapped from './pages/tools/YearInFitnessWrapped';
import LifterPersonalityQuiz from './pages/tools/LifterPersonalityQuiz';
import FastingTimer from './pages/tools/FastingTimer';
import WorkoutRestTimer from './pages/tools/WorkoutRestTimer';
import HiitIntervalTimer from './pages/tools/HiitIntervalTimer';
import SleepCycleCalculator from './pages/tools/SleepCycleCalculator';
import AiFoodPhoto from './pages/tools/AiFoodPhoto';
import AiWorkoutGenerator from './pages/tools/AiWorkoutGenerator';
import AiRoastMyRoutine from './pages/tools/AiRoastMyRoutine';
import FatLossProtocolCalculator from './pages/tools/FatLossProtocolCalculator';
import GlossaryIndex from './pages/glossary';
import GlossaryOneRm from './pages/glossary/OneRm';
import GlossaryTdee from './pages/glossary/Tdee';
import GlossaryBmr from './pages/glossary/Bmr';
import GlossaryMacros from './pages/glossary/Macros';
import GlossaryProgressiveOverload from './pages/glossary/ProgressiveOverload';
import GlossaryRirRpe from './pages/glossary/RirRpe';
import GlossaryDeload from './pages/glossary/Deload';
import GlossaryCutBulk from './pages/glossary/CutBulk';
import GlossaryMesocycle from './pages/glossary/Mesocycle';
import GlossaryWilksScore from './pages/glossary/WilksScore';
import GlossaryBodyFatPercentage from './pages/glossary/BodyFatPercentage';
import GlossarySleepCycles from './pages/glossary/SleepCycles';
import GlossaryIntermittentFasting from './pages/glossary/IntermittentFasting';
import GlossaryVo2Max from './pages/glossary/Vo2Max';
import GlossaryZone2Cardio from './pages/glossary/Zone2Cardio';
import WorkoutVibeGenerator from './pages/tools/WorkoutVibeGenerator';
import AestheticBodyTypeMatcher from './pages/tools/AestheticBodyTypeMatcher';
import CostOfSkippingCalculator from './pages/tools/CostOfSkippingCalculator';
import CaffeineCutoffCalculator from './pages/tools/CaffeineCutoffCalculator';
import RecipeScaler from './pages/tools/RecipeScaler';
import ShouldITrainToday from './pages/tools/ShouldITrainToday';
import WorkoutBuddyCompatibility from './pages/tools/WorkoutBuddyCompatibility';
import MarathonPlanGenerator from './pages/tools/MarathonPlanGenerator';
import ChatWidget from './components/chat/ChatWidget';
// Admin pages
import { AdminLogin, AdminDashboard, LiveChatQueue } from './pages/admin';

// Protected route component for admin pages
function AdminProtectedRoute({ children }: { children: React.ReactNode }) {
  const { isAuthenticated } = useAdminStore();

  if (!isAuthenticated) {
    return <Navigate to="/admin/login" replace />;
  }

  return <>{children}</>;
}

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
        {/* Marketing pages - public */}
        <Route path="/" element={<MarketingLanding />} />
        <Route path="/features" element={<Features />} />
        <Route path="/pricing" element={<Pricing />} />
        {/* Founding 500 Lifetime — web-only, $149.99 one-time. NEVER linked from inside the iOS/Android app. */}
        <Route path="/lifetime" element={<Lifetime />} />
        <Route path="/lifetime/success" element={<LifetimeSuccess />} />
        <Route path="/privacy" element={<PrivacyPolicy />} />
        <Route path="/terms" element={<TermsOfService />} />
        <Route path="/health-disclaimer" element={<HealthDisclaimer />} />
        <Route path="/refunds" element={<RefundPolicy />} />
        <Route path="/faq" element={<FAQ />} />
        <Route path="/about" element={<About />} />
        <Route path="/architecture" element={<Architecture />} />
        <Route path="/contact" element={<Contact />} />
        <Route path="/changelog" element={<Changelog />} />
        <Route path="/roadmap" element={<Roadmap />} />
        <Route path="/waitlist" element={<Waitlist />} />
        <Route path="/delete-account" element={<DeleteAccount />} />
        {/* Comparison pages — SEO */}
        <Route path="/vs/google-health" element={<GoogleHealthVs />} />
        {/* Best-of segment pages — SEO */}
        <Route path="/best-ai-fitness-apps-2026" element={<BestAiFitnessApps2026 />} />
        <Route path="/best-calorie-tracker-apps-2026" element={<BestCalorieTrackerApps2026 />} />
        <Route path="/best-workout-generator-apps-2026" element={<BestWorkoutGeneratorApps2026 />} />
        <Route path="/best-fitbit-alternatives-2026" element={<BestFitbitAlternatives2026 />} />
        <Route path="/best-myfitnesspal-alternatives-2026" element={<BestMyFitnessPalAlternatives2026 />} />
        {/* Free calculator tools — SEO + acquisition funnel */}
        <Route path="/free-tools" element={<ToolsIndex />} />
        <Route path="/free-tools/1rm-calculator" element={<OneRmCalculator />} />
        <Route path="/free-tools/tdee-calculator" element={<TdeeCalculator />} />
        <Route path="/free-tools/bmr-calculator" element={<BmrCalculator />} />
        <Route path="/free-tools/body-fat-calculator" element={<BodyFatCalculator />} />
        <Route path="/free-tools/lean-body-mass-calculator" element={<LeanBodyMassCalculator />} />
        <Route path="/free-tools/bmi-calculator" element={<BmiCalculator />} />
        <Route path="/free-tools/ideal-weight-calculator" element={<IdealWeightCalculator />} />
        <Route path="/free-tools/healthy-weight-calculator" element={<HealthyWeightCalculator />} />
        <Route path="/free-tools/macro-calculator" element={<MacroCalculator />} />
        <Route path="/free-tools/adaptive-macro-calculator" element={<AdaptiveMacroCalculator />} />
        <Route path="/free-tools/adaptive-calorie-calculator" element={<AdaptiveCalorieCalculator />} />
        <Route path="/free-tools/protein-per-meal-calculator" element={<ProteinPerMealCalculator />} />
        <Route path="/free-tools/carb-cycling-calculator" element={<CarbCyclingCalculator />} />
        <Route path="/free-tools/calories-burned-calculator" element={<CaloriesBurnedCalculator />} />
        <Route path="/free-tools/wilks-calculator" element={<WilksCalculator />} />
        <Route path="/free-tools/dots-calculator" element={<DotsCalculator />} />
        <Route path="/free-tools/ipf-gl-calculator" element={<IpfGlCalculator />} />
        <Route path="/free-tools/schwartz-malone-calculator" element={<SchwartzMaloneCalculator />} />
        <Route path="/free-tools/strength-level" element={<StrengthLevel />} />
        <Route path="/free-tools/plate-loader" element={<PlateLoader />} />
        <Route path="/free-tools/rir-rpe-converter" element={<RirRpeConverter />} />
        <Route path="/free-tools/vo2-max-calculator" element={<Vo2MaxCalculator />} />
        <Route path="/free-tools/sweat-rate-calculator" element={<SweatRateCalculator />} />
        <Route path="/free-tools/pace-calculator" element={<PaceCalculator />} />
        <Route path="/free-tools/target-heart-rate-calculator" element={<TargetHeartRateCalculator />} />
        <Route path="/free-tools/workout-volume-calculator" element={<WorkoutVolumeCalculator />} />
        <Route path="/free-tools/mesocycle-volume-calculator" element={<MesocycleVolumeCalculator />} />
        <Route path="/free-tools/deload-week-calculator" element={<DeloadWeekCalculator />} />
        <Route path="/free-tools/cut-bulk-duration-calculator" element={<CutBulkDurationCalculator />} />
        <Route path="/free-tools/tapering-calculator" element={<TaperingCalculator />} />
        <Route path="/free-tools/photo-comparison" element={<PhotoComparison />} />
        <Route path="/free-tools/pr-celebration-card" element={<PrCelebrationCard />} />
        <Route path="/free-tools/streak-certificate" element={<StreakCertificate />} />
        <Route path="/free-tools/workout-summary-card" element={<WorkoutSummaryCard />} />
        <Route path="/free-tools/year-in-fitness-wrapped" element={<YearInFitnessWrapped />} />
        <Route path="/free-tools/lifter-personality-quiz" element={<LifterPersonalityQuiz />} />
        <Route path="/free-tools/fasting-timer" element={<FastingTimer />} />
        <Route path="/free-tools/workout-rest-timer" element={<WorkoutRestTimer />} />
        <Route path="/free-tools/hiit-interval-timer" element={<HiitIntervalTimer />} />
        <Route path="/free-tools/sleep-cycle-calculator" element={<SleepCycleCalculator />} />
        <Route path="/free-tools/ai-food-photo" element={<AiFoodPhoto />} />
        <Route path="/free-tools/ai-workout-generator" element={<AiWorkoutGenerator />} />
        <Route path="/free-tools/ai-roast-my-routine" element={<AiRoastMyRoutine />} />
        <Route path="/free-tools/fat-loss-protocol-calculator" element={<FatLossProtocolCalculator />} />
        {/* Glossary pages — definition-style content, ranks for "what is X" + AI Overviews */}
        <Route path="/glossary" element={<GlossaryIndex />} />
        <Route path="/glossary/1rm" element={<GlossaryOneRm />} />
        <Route path="/glossary/tdee" element={<GlossaryTdee />} />
        <Route path="/glossary/bmr" element={<GlossaryBmr />} />
        <Route path="/glossary/macros" element={<GlossaryMacros />} />
        <Route path="/glossary/progressive-overload" element={<GlossaryProgressiveOverload />} />
        <Route path="/glossary/rir-rpe" element={<GlossaryRirRpe />} />
        <Route path="/glossary/deload" element={<GlossaryDeload />} />
        <Route path="/glossary/cut-bulk" element={<GlossaryCutBulk />} />
        <Route path="/glossary/mesocycle" element={<GlossaryMesocycle />} />
        <Route path="/glossary/wilks-score" element={<GlossaryWilksScore />} />
        <Route path="/glossary/body-fat-percentage" element={<GlossaryBodyFatPercentage />} />
        <Route path="/glossary/sleep-cycles" element={<GlossarySleepCycles />} />
        <Route path="/glossary/intermittent-fasting" element={<GlossaryIntermittentFasting />} />
        <Route path="/glossary/vo2-max" element={<GlossaryVo2Max />} />
        <Route path="/glossary/zone-2-cardio" element={<GlossaryZone2Cardio />} />
        <Route path="/free-tools/workout-vibe-generator" element={<WorkoutVibeGenerator />} />
        <Route path="/free-tools/aesthetic-body-type-matcher" element={<AestheticBodyTypeMatcher />} />
        <Route path="/free-tools/cost-of-skipping-calculator" element={<CostOfSkippingCalculator />} />
        <Route path="/free-tools/caffeine-cutoff-calculator" element={<CaffeineCutoffCalculator />} />
        <Route path="/free-tools/recipe-scaler" element={<RecipeScaler />} />
        <Route path="/free-tools/should-i-train-today" element={<ShouldITrainToday />} />
        <Route path="/free-tools/workout-buddy-compatibility" element={<WorkoutBuddyCompatibility />} />
        <Route path="/free-tools/marathon-plan-generator" element={<MarathonPlanGenerator />} />
        {/* Referral invite landing page. iOS/Android opens the app via
            the `fitwiz://` scheme if installed (see Invite.tsx); desktop
            or not-installed → show the code + store CTAs. */}
        <Route path="/invite/:code" element={<Invite />} />
        {/* Public workout share — anyone can view; backend resolves the
            opaque token via /api/v1/workouts/public/{token}. */}
        <Route path="/w/:token" element={<PublicWorkout />} />
        {/* Legacy landing page */}
        <Route path="/app" element={<Landing />} />
        {/* Protected home (dashboard) */}
        <Route
          path="/home"
          element={isValidUser ? <Home /> : <Navigate to="/login" replace />}
        />
        {/* /login removed — redirects to home page */}
        <Route path="/login" element={<Navigate to="/" replace />} />
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

        {/* Admin Routes */}
        <Route path="/admin/login" element={<AdminLogin />} />
        <Route
          path="/admin/dashboard"
          element={
            <AdminProtectedRoute>
              <AdminDashboard />
            </AdminProtectedRoute>
          }
        />
        <Route
          path="/admin/chats"
          element={
            <AdminProtectedRoute>
              <LiveChatQueue />
            </AdminProtectedRoute>
          }
        />
        {/* Redirect /admin to /admin/dashboard */}
        <Route path="/admin" element={<Navigate to="/admin/dashboard" replace />} />
      </Routes>
      {/* Global Chat Widget - renders via portal, only for authenticated users */}
      {isValidUser && <ChatWidget />}
    </>
  );
}

export default App;
